#!/usr/bin/env bash
# Stop / SessionEnd: capture reminder (does not write to kb automatically).
# Usage: kb-session-end.sh [Stop|SessionEnd]
set -euo pipefail

EVENT="${1:-Stop}"
KB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -t 0 ]; then
  STDIN_DATA=""
else
  STDIN_DATA=$(cat)
fi
if echo "$STDIN_DATA" | jq -e '.stop_hook_active == true' >/dev/null 2>&1; then
  echo '{"continue": false}'
  exit 0
fi

CONTEXT="CAPTURE (agent-knowledge): did anything genuinely new and reusable come up (gotcha, decision, business fact, rejected approach)?
→ hotfix/incident: template kb/templates/hotfix-kb-capture.md
→ regular fact: echo \"body\" | bin/kb-capture.sh <category> <slug> \"<title>\" [tags]
→ don't repeat/retro: kb/templates/dont-repeat-capture.md → bin/kb-dont-repeat.sh
→ before capture: kb-search.sh for duplicates. Nothing new — skip it.
Categories: rules · preferences · best-practices · anti-patterns · architecture · business-logic · errors · code-reviews · playbooks
Constitution: GOVERNANCE.md §6"

DOCTOR_STAMP="$KB/.last-kb-doctor"
DOCTOR_DUE=0
if [ ! -f "$DOCTOR_STAMP" ]; then
  DOCTOR_DUE=1
else
  NOW_EPOCH=$(date +%s)
  STAMP_EPOCH=$(stat -f %m "$DOCTOR_STAMP" 2>/dev/null || stat -c %Y "$DOCTOR_STAMP" 2>/dev/null || echo 0)
  [ $((NOW_EPOCH - STAMP_EPOCH)) -gt $((28 * 86400)) ] && DOCTOR_DUE=1
fi
if [ "$DOCTOR_DUE" -eq 1 ]; then
  CONTEXT="$CONTEXT

MAINTENANCE: every ~4 weeks — bin/kb-doctor.sh --sim 0.5
After kb/ edits: bin/kb-index.sh"
fi

# shellcheck source=_emit.sh
source "$(dirname "${BASH_SOURCE[0]}")/_emit.sh"
kb_emit_context "$EVENT" "$CONTEXT"
