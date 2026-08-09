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
[ "$COUNT" -ge 7 ] || fail "kb-index: expected ≥7 indexed notes, got $COUNT"
pass "kb-index indexes notes ($COUNT)"

# --- kb-search (BM25 + rules boost) ---
SEARCH_OUT="$("$TMP/bin/kb-search.sh" "force push shared branch" 2>/dev/null || true)"
echo "$SEARCH_OUT" | grep -qi 'force' || fail "kb-search: no match for force push"
echo "$SEARCH_OUT" | grep -qi 'git' || fail "kb-search: git rule not in results"
pass "kb-search finds git / force-push content"

RULES_FIRST="$("$TMP/bin/kb-search.sh" "git workflow commit" 2>/dev/null | head -1 || true)"
echo "$RULES_FIRST" | grep -qi 'rules/hard' || fail "kb-search: hard rules not boosted in top hit"
pass "kb-search ranks rules with hard severity"

# --- kb-capture ---
SLUG="test-capture-$$"
BODY="Temporary note for integration test."
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

# --- kb/ structure ---
python3 - <<'PY' "$TMP/kb"
import glob, os, re, sys
kb = sys.argv[1]
bad = []
for path in glob.glob(os.path.join(kb, "**", "*.md"), recursive=True):
    base = os.path.basename(path)
    if base.startswith("_"):
        continue
    rel = os.path.relpath(path, kb)
    if rel.startswith("templates/"):
        continue
    text = open(path, encoding="utf-8").read()
    if not text.startswith("---"):
        bad.append(f"{rel}: no frontmatter")
        continue
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    if not m:
        bad.append(f"{rel}: bad frontmatter")
        continue
    fm = m.group(1)
    for key in ("id", "category"):
        if not re.search(rf"^{key}:", fm, re.M):
            bad.append(f"{rel}: missing {key}")
if bad:
    print("\n".join(bad))
    sys.exit(1)
PY
pass "kb/ frontmatter structure"

echo
echo "All tests passed."
