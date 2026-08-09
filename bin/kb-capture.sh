#!/usr/bin/env bash
# Add ONE genuinely new note to kb/ and rebuild the index.
# usage: echo "body" | kb-capture.sh <category> <slug> "<title>" [tags...]
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KB_ROOT="${KB_ROOT:-$(cd "$SELF_DIR/.." && pwd)}"

CATEGORY="${1:-}"; SLUG="${2:-}"; TITLE="${3:-}"
if [ -z "$CATEGORY" ] || [ -z "$SLUG" ] || [ -z "$TITLE" ]; then
  echo 'usage: kb-capture.sh <category> <slug> "<title>" [tags...]' >&2
  exit 1
fi
shift 3 || true
TAGS_JSON=$(printf '%s' "$*" | tr -s ' ' '\n' | awk 'NF' | paste -sd', ' -)

SEVERITY="info"; [ "$CATEGORY" = "rules" ] && SEVERITY="hard"

DIR="$KB_ROOT/kb/$CATEGORY"; mkdir -p "$DIR"
FILE="$DIR/$SLUG.md"
if [ -e "$FILE" ]; then
  echo "[kb-capture] already exists: $FILE — edit it manually, don't create a duplicate." >&2
  exit 1
fi

DUP="$(KB_SIZE=1 "$SELF_DIR/kb-search.sh" "$TITLE" 2>/dev/null | head -1 || true)"
[ -n "$DUP" ] && echo "[kb-capture] similar note already in the base: ${DUP#### } — check it's not a duplicate." >&2

if [ ! -t 0 ]; then BODY="$(cat)"; else BODY="(fill in the note body)"; fi
TODAY=$(date +%Y-%m-%d)
{
  printf -- '---\n'
  printf 'id: %s\ncategory: %s\nservice: "*"\nseverity: %s\ntags: [%s]\ncreated: %s\nsource: session\n' \
    "$SLUG" "$CATEGORY" "$SEVERITY" "$TAGS_JSON" "$TODAY"
  printf -- '---\n\n# %s\n\n%s\n' "$TITLE" "$BODY"
} > "$FILE"

echo "[kb-capture] created: $FILE"
"$SELF_DIR/kb-index.sh" >/dev/null && echo "[kb-capture] index rebuilt"
