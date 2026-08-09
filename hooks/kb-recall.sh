#!/usr/bin/env bash
# UserPromptSubmit / beforeSubmitPrompt: FTS top 2 compact + component stub if mentioned.
set -euo pipefail

KB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INPUT="$(cat || true)"
PROMPT="$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || true)"
[ -z "$PROMPT" ] && exit 0
[ "${#PROMPT}" -lt 8 ] && exit 0

PARTS=()

RECALL="$(KB_SIZE=2 KB_COMPACT=1 "$KB/bin/kb-search.sh" "$PROMPT" 2>/dev/null || true)"
[ -n "$RECALL" ] && PARTS+=("kb (background; project beats model):
$RECALL")

STUB_PACK=""
PICK=""
# Every component with a stub note (heading "# Stub: <name>").
CANDS="$(rg --no-filename --no-line-number -o '^#[[:space:]]*Stub:[[:space:]]*([a-zA-Z0-9_-]+)' -r '$1' "$KB/kb" 2>/dev/null | sort -u || true)"
while IFS= read -r svc; do
  [ -z "$svc" ] && continue
  if printf '%s' "$PROMPT" | grep -qiE "\b${svc}\b"; then PICK="$svc"; break; fi
done <<EOF
$CANDS
EOF

[ -n "$PICK" ] && STUB_PACK="$(KB_SIZE=1 KB_COMPACT=1 "$KB/bin/kb-search.sh" "stub ${PICK}" 2>/dev/null || true)"
if [ -n "$STUB_PACK" ]; then
  PARTS+=("COMPONENT STUB:
$STUB_PACK")
fi

[ "${#PARTS[@]}" -eq 0 ] && exit 0

CONTEXT="$(printf '%s\n' "${PARTS[@]}" | paste -sd $'\n\n' -)"

# shellcheck source=_emit.sh
source "$(dirname "${BASH_SOURCE[0]}")/_emit.sh"
kb_emit_context "UserPromptSubmit" "$CONTEXT"
