#!/usr/bin/env bash
# Regenerate docs/demo.cast and docs/demo.gif via asciinema + agg.
# Requires: brew install asciinema agg
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

command -v asciinema >/dev/null 2>&1 || { echo "install: brew install asciinema agg" >&2; exit 1; }
command -v agg >/dev/null 2>&1 || { echo "install: brew install asciinema agg" >&2; exit 1; }

asciinema rec --overwrite --idle-time-limit 1 \
  -c "bash scripts/demo-recording.sh" \
  -t "agent-knowledge demo" \
  docs/demo.cast

agg --font-size 14 docs/demo.cast docs/demo.gif

echo "Written docs/demo.cast and docs/demo.gif"
