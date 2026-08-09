#!/usr/bin/env bash
# Build local SQLite FTS5 index from kb/ (+ optional Claude memory).
# No daemons: one kb.db file, BM25 ranking, rebuild in under a second.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export KB_ROOT="${KB_ROOT:-$(cd "$SELF_DIR/.." && pwd)}"
export KB_DB="${KB_DB:-$KB_ROOT/kb.db}"
# Optional: also index ~/.claude/projects/<slug>/memory/*.md (category: memory).
# Example: export KB_MEMORY_DIR="$HOME/.claude/projects/-Users-you-myproject/memory"
export KB_MEMORY_DIR="${KB_MEMORY_DIR:-}"

python3 - <<'PY'
import os, glob, re, sqlite3

ROOT = os.environ["KB_ROOT"]
DB   = os.environ["KB_DB"]
MEM  = os.environ.get("KB_MEMORY_DIR", "")

def parse(text):
    fm, body = {}, text
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n(.*)$", text, re.S)
    if m:
        raw, body = m.group(1), m.group(2)
        for line in raw.splitlines():
            if ":" in line:
                k, v = line.split(":", 1)
                fm[k.strip()] = v.strip()
    return fm, body.strip()

def title_of(body, fb):
    for ln in body.splitlines():
        if ln.startswith("# "):
            return ln[2:].strip()
    return fb

def tags_str(v):
    if v and v.startswith("[") and v.endswith("]"):
        return " ".join(t.strip().strip('"') for t in v[1:-1].split(",") if t.strip())
    return v or ""

rows = []
for path in glob.glob(os.path.join(ROOT, "kb", "**", "*.md"), recursive=True):
    base = os.path.basename(path)
    if base.startswith("_") or base.lower() == "readme.md":
        continue
    # examples/ and templates/ are helpers, not project knowledge
    norm = path.replace("\\", "/")
    if "/examples/" in norm or "/templates/" in norm:
        continue
    fm, body = parse(open(path, encoding="utf-8").read())
    cat = fm.get("category") or os.path.basename(os.path.dirname(path))
    rows.append((title_of(body, base), tags_str(fm.get("tags")), fm.get("service", "*"),
                 body, fm.get("id", os.path.splitext(base)[0]), cat, fm.get("severity", "info"), path))

if MEM and os.path.isdir(MEM):
    for path in glob.glob(os.path.join(MEM, "*.md")):
        base = os.path.basename(path)
        if base == "MEMORY.md":
            continue
        fm, body = parse(open(path, encoding="utf-8").read())
        rows.append((title_of(body, base), "", "*", body,
                     "memory-" + os.path.splitext(base)[0], "memory", "info", path))

conn = sqlite3.connect(DB)
conn.execute("DROP TABLE IF EXISTS kb")
conn.execute("""CREATE VIRTUAL TABLE kb USING fts5(
    title, tags, service, body,
    id UNINDEXED, category UNINDEXED, severity UNINDEXED, path UNINDEXED,
    tokenize = 'unicode61')""")
conn.executemany("INSERT INTO kb(title,tags,service,body,id,category,severity,path) VALUES(?,?,?,?,?,?,?,?)", rows)
conn.commit()
conn.close()
print(f"[kb-index] {len(rows)} notes → {DB}")
PY
