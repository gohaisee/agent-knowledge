#!/usr/bin/env bash
# SessionStart: short wake-up. Details in GOVERNANCE.md + kb-search.
set -euo pipefail

KB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RULES=""
if [ -f "$KB/kb.db" ]; then
  RULES="$(KB_SIZE=2 KB_COMPACT=1 "$KB/bin/kb-search.sh" "rules capture dont-repeat" 2>/dev/null || true)"
fi

CONTEXT="MEMORY (agent-knowledge) sessionStart
Constitution: GOVERNANCE.md
Search: bin/kb-search.sh · capture: bin/kb-capture.sh · index: bin/kb-index.sh
Priority: kb/rules > preferences > model."

if [ -n "$RULES" ]; then
  CONTEXT="$CONTEXT

kb:
$RULES"
fi

# shellcheck source=_emit.sh
source "$(dirname "${BASH_SOURCE[0]}")/_emit.sh"
kb_emit_context "SessionStart" "$CONTEXT"
