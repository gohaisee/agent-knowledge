#!/usr/bin/env bash
# Search the knowledge base. SQLite FTS5 (BM25), ripgrep fallback if no index yet.
# env: KB_SIZE (how many hits), KB_COMPACT=1 (trim body — for recall hook).
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export KB_ROOT="${KB_ROOT:-$(cd "$SELF_DIR/.." && pwd)}"
export KB_DB="${KB_DB:-$KB_ROOT/kb.db}"
export KB_SIZE="${KB_SIZE:-5}"
export KB_QUERY="$*"

[ -z "$KB_QUERY" ] && { echo "usage: kb-search.sh <query...>" >&2; exit 1; }

# --- SQLite FTS5 path ---
if [ -f "$KB_DB" ] && command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
import os, re, sqlite3
DB   = os.environ["KB_DB"]
SIZE = int(os.environ.get("KB_SIZE", "5"))
COMP = bool(os.environ.get("KB_COMPACT"))
q    = os.environ["KB_QUERY"].lower()
STOP = {
    "the","and","for","with","this","that","have","has","you","your","can","will","would",
    "should","make","add","fix","please","how","what","why","does","are","was","but","not",
    "just","also","from","into","about","when","where","which","been","being","were","they",
    "them","then","than","some","such","only","other","more","most","very","much","like",
}
toks = [t for t in re.findall(r"[0-9a-zA-Z]+", q) if len(t) >= 3 and t not in STOP][:24]
if not toks:
    raise SystemExit(0)
match = " OR ".join('"%s"' % t for t in toks)
conn = sqlite3.connect(DB)
try:
    pool = max(SIZE * 4, 12)
    rows = conn.execute(
        "SELECT title,category,severity,body, bm25(kb, 10.0, 6.0, 3.0, 1.0) AS rank FROM kb WHERE kb MATCH ? "
        "ORDER BY rank LIMIT ?", (match, pool)).fetchall()
except sqlite3.OperationalError:
    rows = []

def boost(row):
    title, cat, sev, body, rank = row
    bonus = 0.0
    if (sev or "").lower() == "hard":
        bonus += 1.5
    if (cat or "") in ("rules", "preferences", "playbooks"):
        bonus += 1.0
    if (cat or "") == "playbooks":
        bonus += 0.5
    return (rank - bonus, rank, title, cat, sev, body)

ranked = sorted(boost(r) for r in rows)[:SIZE]
for _key, _raw, title, cat, sev, body in ranked:
    if COMP and len(body) > 280:
        body = body[:280].rstrip() + "…"
    print(f"### {title}  [{cat}/{sev}]")
    print(body)
    print("---")
PY
  exit 0
fi

# --- fallback: ripgrep when index isn't built yet ---
command -v rg >/dev/null 2>&1 || { echo "[kb-search] need kb.db or ripgrep" >&2; exit 0; }
PATTERN=$(printf '%s' "$KB_QUERY" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '\n' | awk 'length>=3' | paste -sd'|' -)
[ -z "$PATTERN" ] && exit 0
rg -i -l -e "$PATTERN" -tmd "$KB_ROOT/kb" 2>/dev/null | head -n "$KB_SIZE" | while IFS= read -r f; do
  printf '### %s\n' "$(basename "$f" .md)"
  awk 'BEGIN{fm=0} /^---[[:space:]]*$/{fm++; next} fm>=2{print}' "$f"
  printf -- '---\n'
done
