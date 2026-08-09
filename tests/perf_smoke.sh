#!/usr/bin/env bash
# Smoke: index 1000 synthetic notes in under PERF_MAX_SEC (default 15 on CI).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PERF_MAX_SEC="${PERF_MAX_SEC:-15}"
N="${PERF_NOTE_COUNT:-1000}"

rsync -a --exclude '.git' --exclude 'kb.db*' "$REPO_ROOT/bin" "$REPO_ROOT/kb/_TEMPLATE.md" "$TMP/"
mkdir -p "$TMP/kb/best-practices"

python3 - <<'PY' "$TMP/kb/best-practices" "$N"
import os, sys
out, n = sys.argv[1], int(sys.argv[2])
for i in range(n):
    slug = f"load-note-{i:04d}"
    path = os.path.join(out, f"{slug}.md")
    open(path, "w", encoding="utf-8").write(f"""---
id: {slug}
category: best-practices
service: "*"
severity: info
tags: [load-test]
created: 2026-08-09
source: perf
---

# Load test note {i}

Synthetic note for index performance smoke test. Topic keyword: deployment rollback canary {i}.

**Why:** generated fixture, not real knowledge.

**How to apply:** ignore in production kb/.
""")
PY

export KB_ROOT="$TMP"
export KB_DB="$TMP/kb.db"

START=$(python3 -c "import time; print(time.time())")
"$TMP/bin/kb-index.sh" >/dev/null
END=$(python3 -c "import time; print(time.time())")
ELAPSED=$(python3 -c "print(round($END - $START, 2))")

COUNT="$(python3 -c "import sqlite3; c=sqlite3.connect('$TMP/kb.db'); print(c.execute('SELECT COUNT(*) FROM kb').fetchone()[0])")"

echo "[perf] indexed $COUNT notes in ${ELAPSED}s (limit ${PERF_MAX_SEC}s)"

python3 -c "import sys; sys.exit(0 if float('$ELAPSED') <= float('$PERF_MAX_SEC') else 1)" || {
  echo "[perf] FAIL: too slow" >&2
  exit 1
}
