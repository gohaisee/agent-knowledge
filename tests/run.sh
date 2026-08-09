#!/usr/bin/env bash
# Integration tests for kb-index, kb-search, kb-capture. Runs in a temp copy of the repo.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

copy_tree() {
  rsync -a \
    --exclude '.git' \
    --exclude 'kb.db' \
    --exclude 'kb.db-*' \
    --exclude '.last-kb-doctor' \
    "$REPO_ROOT/" "$TMP/"
}

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "ok  $*"; }

# --- repo kb/ must pass validate before temp copy ---
"$REPO_ROOT/bin/kb-validate.sh" || fail "kb-validate on repo"
pass "kb-validate on repo"

copy_tree
export KB_ROOT="$TMP"
export KB_DB="$TMP/kb.db"

# --- kb-index ---
"$TMP/bin/kb-index.sh" | grep -q 'notes →'
COUNT="$(
  python3 - <<'PY'
import os, sqlite3
db = os.environ["KB_DB"]
conn = sqlite3.connect(db)
n = conn.execute("SELECT COUNT(*) FROM kb").fetchone()[0]
print(n)
conn.close()
PY
)"
[ "$COUNT" -ge 8 ] || fail "kb-index: expected ≥8 indexed notes, got $COUNT"
pass "kb-index indexes notes ($COUNT)"

# --- kb-search ranking (BM25 + category/severity boost) ---
rank() {
  KB_DB="$KB_DB" python3 "$REPO_ROOT/tests/search_rank.py" "$@"
}

FORCE_TOP="$(rank "force push main master shared branch" | head -1)"
[[ "$FORCE_TOP" == "Never force-push shared branches" ]] || fail "rank: force-push query top=$FORCE_TOP"
pass "BM25 order: force-push note ranks first"

ASK_TOP="$(rank "commit push merge request explicit user asked" | head -1)"
[[ "$ASK_TOP" == "Git operations only when asked" ]] || fail "rank: git-permission query top=$ASK_TOP"
pass "BM25 order: permission note ranks first"

SETUP_TOP="$(rank "agent knowledge index hooks setup onboarding" | head -1)"
case "$SETUP_TOP" in
  "How to use agent-knowledge"|"System overview (demo)") ;;
  *) fail "rank: setup query top=$SETUP_TOP (expected onboarding note, not git rule)" ;;
esac
pass "BM25 order: onboarding beats unrelated rules ($SETUP_TOP)"

FORCE_RANK="$(rank "force push rewrite remote history")"
[[ "$(echo "$FORCE_RANK" | head -1)" == "Never force-push shared branches" ]] || fail "rank: force-push specificity lost top slot"
echo "$FORCE_RANK" | head -2 | grep -q "Never force-push shared branches" || fail "rank: force-push missing from top 2"
pass "BM25 order: force-push stays in top results on history rewrite query"

# --- kb-search CLI smoke ---
SEARCH_OUT="$("$TMP/bin/kb-search.sh" "force push shared branch" 2>/dev/null || true)"
echo "$SEARCH_OUT" | grep -qi 'force' || fail "kb-search CLI: no match for force push"
pass "kb-search CLI returns force-push content"

# --- kb-capture ---
SLUG="test-capture-$$"
BODY="Temporary note for integration test. Must be long enough for kb-validate minimum body length check."
echo "$BODY" | "$TMP/bin/kb-capture.sh" best-practices "$SLUG" "Test capture note" demo test

NOTE="$TMP/kb/best-practices/$SLUG.md"
[ -f "$NOTE" ] || fail "kb-capture: file not created"
grep -q "^id: $SLUG" "$NOTE" || fail "kb-capture: frontmatter id missing"
grep -q "$BODY" "$NOTE" || fail "kb-capture: body missing"

AFTER="$(
  python3 - <<'PY'
import os, sqlite3
conn = sqlite3.connect(os.environ["KB_DB"])
print(conn.execute("SELECT COUNT(*) FROM kb").fetchone()[0])
conn.close()
PY
)"
[ "$AFTER" -gt "$COUNT" ] || fail "kb-capture: index count did not increase"
pass "kb-capture creates note and rebuilds index"

if echo "dup" | "$TMP/bin/kb-capture.sh" best-practices "$SLUG" "Dup" 2>/dev/null; then
  fail "kb-capture: duplicate slug should exit non-zero"
fi
pass "kb-capture rejects duplicate slug"

# --- kb-validate on temp tree ---
"$TMP/bin/kb-validate.sh" || fail "kb-validate on temp tree"
pass "kb-validate on temp tree"

# --- broken frontmatter fails validate ---
printf '%s\n' 'no frontmatter here' > "$TMP/kb/best-practices/broken-note.md"
if "$TMP/bin/kb-validate.sh" 2>/dev/null; then
  fail "kb-validate should reject broken frontmatter"
fi
rm -f "$TMP/kb/best-practices/broken-note.md"
pass "kb-validate rejects missing frontmatter"

echo
echo "All integration tests passed."
