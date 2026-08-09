#!/usr/bin/env bash
# Shared hook output for Cursor and Claude Code.
# Usage: source _emit.sh && kb_emit_context "<HookEventName>" "$CONTEXT"
kb_emit_context() {
  local event="${1:-UserPromptSubmit}"
  local ctx="${2:-}"
  jq -n --arg e "$event" --arg c "$ctx" '{
    continue: true,
    additional_context: $c,
    hookSpecificOutput: {
      hookEventName: $e,
      additionalContext: $c
    }
  }'
}

kb_dir() {
  cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")/.." && pwd
}

workspace_root() {
  cd "$(kb_dir)/.." && pwd
}
