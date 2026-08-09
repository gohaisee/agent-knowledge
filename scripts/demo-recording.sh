#!/usr/bin/env bash
# Terminal demo for asciinema → GIF. Shows index, search, hook recall.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export TERM=xterm-256color
sleep 0.4

printf '\n# agent-knowledge demo (~30s)\n'
sleep 0.8

printf '\n$ bin/kb-index.sh\n'
sleep 0.5
bin/kb-index.sh
sleep 1.2

printf '\n$ bin/kb-search.sh "force push main"\n'
sleep 0.5
bin/kb-search.sh "force push main" | head -20
sleep 1.5

printf '\n$ echo prompt | hooks/kb-recall.sh  (hook injects top matches)\n'
sleep 0.5
printf '%s\n' '{"prompt":"Should we force push to main after the hotfix?"}' | hooks/kb-recall.sh | python3 -c "
import json, sys
d = json.load(sys.stdin)
ctx = d.get('additional_context', '')
# Show first ~600 chars — what the agent sees
print(ctx[:600] + ('…' if len(ctx) > 600 else ''))
"
sleep 1.5

printf '\n# kb recall attached relevant rules to the prompt\n'
sleep 0.8
