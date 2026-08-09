#!/usr/bin/env bash
# Session exit "don't repeat": optional capture + mistakes bullet + optional ci-triage row.
# usage:
#   echo "short mistakes bullet" | kb-dont-repeat.sh \
#     --slug my-slug --title "Short title" --category errors \
#     [--triage-row "symptom|verdict|action"] \
#     [--section "Dont-repeat YYYY-MM-DD"] \
#     [--no-capture] \
#     [tags...]
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KB_ROOT="${KB_ROOT:-$(cd "$SELF_DIR/.." && pwd)}"
MISTAKES="$KB_ROOT/kb/preferences/agent-session-mistakes.md"
TRIAGE="$KB_ROOT/kb/rules/ci-triage-quick.md"

SLUG=""; TITLE=""; CATEGORY=""; TRIAGE_ROW=""; SECTION=""; NO_CAPTURE=0
TAGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --slug) SLUG="${2:-}"; shift 2 ;;
    --title) TITLE="${2:-}"; shift 2 ;;
    --category) CATEGORY="${2:-}"; shift 2 ;;
    --triage-row) TRIAGE_ROW="${2:-}"; shift 2 ;;
    --section) SECTION="${2:-}"; shift 2 ;;
    --no-capture) NO_CAPTURE=1; shift ;;
    -h|--help)
      sed -n '2,12p' "$0" | tr -d '#'
      exit 0
      ;;
    --*)
      echo "[kb-dont-repeat] unknown flag: $1" >&2
      exit 1
      ;;
    *)
      TAGS+=("$1"); shift
      ;;
  esac
done

if [ -z "$SLUG" ] || [ -z "$TITLE" ] || [ -z "$CATEGORY" ]; then
  echo 'usage: echo "bullet" | kb-dont-repeat.sh --slug S --title "T" --category C [--triage-row "a|b|c"] [tags...]' >&2
  exit 1
fi

if [ ! -t 0 ]; then
  ITEM="$(cat)"
else
  echo "[kb-dont-repeat] need stdin: short bullet for mistakes (1–3 sentences)" >&2
  exit 1
fi
ITEM="$(printf '%s' "$ITEM" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
[ -z "$ITEM" ] && { echo "[kb-dont-repeat] empty stdin" >&2; exit 1; }

TODAY=$(date +%Y-%m-%d)
[ -z "$SECTION" ] && SECTION="Dont-repeat $TODAY"

CAPTURE_STATUS="skip"
FILE="$KB_ROOT/kb/$CATEGORY/$SLUG.md"
if [ "$NO_CAPTURE" -eq 0 ]; then
  if [ -e "$FILE" ]; then
    CAPTURE_STATUS="exists"
    echo "[kb-dont-repeat] capture skip: already exists $FILE" >&2
  else
    BODY=$(cat <<EOF
## Symptom / lesson
$ITEM

## Canon
"Don't repeat" bullet is in [[agent-session-mistakes]].
EOF
)
    printf '%s\n' "$BODY" | "$SELF_DIR/kb-capture.sh" "$CATEGORY" "$SLUG" "$TITLE" "${TAGS[@]+"${TAGS[@]}"}"
    CAPTURE_STATUS="OK"
  fi
else
  CAPTURE_STATUS="no-capture"
fi

# --- mistakes: next number + section + bullet ---
[ -f "$MISTAKES" ] || { echo "[kb-dont-repeat] missing mistakes file: $MISTAKES" >&2; exit 1; }

NEXT=$(python3 - <<'PY' "$MISTAKES"
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
nums = [int(m.group(1)) for m in re.finditer(r"(?m)^(\d+)\.\s+\*\*", text)]
print(max(nums) + 1 if nums else 1)
PY
)

# Skip if slug link already present
if grep -q "\[\[${SLUG}\]\]" "$MISTAKES" 2>/dev/null; then
  echo "[kb-dont-repeat] mistakes: [[$SLUG]] already there — skipping bullet" >&2
  MISTAKES_STATUS="exists"
else
  BULLET="${NEXT}. **${TITLE}** — ${ITEM} [[${SLUG}]]."
  python3 - <<'PY' "$MISTAKES" "$SECTION" "$BULLET" "$TODAY"
import re, sys
path, section, bullet, today = sys.argv[1:5]
text = open(path, encoding="utf-8").read()
text2, n = re.subn(r"(?m)^updated:.*$", f"updated: {today}", text, count=1)
if n == 0:
    text2 = text
m = re.search(r"(?m)^## ", text2)
block = f"\n## {section}\n\n{bullet}\n"
if not m:
    text2 = text2.rstrip() + "\n" + block + "\n"
else:
    text2 = text2[: m.start()] + block + "\n" + text2[m.start():]
open(path, "w", encoding="utf-8").write(text2)
print(bullet)
PY
  MISTAKES_STATUS="OK"
fi

# --- triage row ---
TRIAGE_STATUS="skip"
TAGS_JOINED=$(printf '%s ' "${TAGS[@]+"${TAGS[@]}"}" | tr '[:upper:]' '[:lower:]')
NEED_TRIAGE=0
[ -n "$TRIAGE_ROW" ] && NEED_TRIAGE=1
printf '%s' "$TAGS_JOINED" | grep -Eq '(^|[[:space:]])(ci|gitlab|oom|runner)([[:space:]]|$)' && NEED_TRIAGE=1

if [ "$NEED_TRIAGE" -eq 1 ]; then
  if [ -z "$TRIAGE_ROW" ]; then
    TRIAGE_ROW="${TITLE}|see lesson|${ITEM} [[${SLUG}]]"
  fi
  IFS='|' read -r COL1 COL2 COL3 <<EOF
$TRIAGE_ROW
EOF
  COL1=$(printf '%s' "$COL1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  COL2=$(printf '%s' "$COL2" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  COL3=$(printf '%s' "$COL3" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  ROW="| ${COL1} | ${COL2} | ${COL3} |"
  if grep -Fq "[[${SLUG}]]" "$TRIAGE" 2>/dev/null; then
    TRIAGE_STATUS="exists"
    echo "[kb-dont-repeat] triage: [[$SLUG]] already there" >&2
  elif grep -Fq "$ROW" "$TRIAGE" 2>/dev/null; then
    TRIAGE_STATUS="exists"
  else
    python3 - <<'PY' "$TRIAGE" "$ROW"
import re, sys
path, row = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
m = re.search(r"(?m)^\s*\|[-| :]+\|\s*$", text)
if not m:
    raise SystemExit("no triage table separator found")
idx = m.end()
if idx < len(text) and text[idx] == "\n":
    insert_at = idx + 1
else:
    insert_at = idx
text = text[:insert_at] + row + "\n" + text[insert_at:]
open(path, "w", encoding="utf-8").write(text)
PY
    TRIAGE_STATUS="OK"
  fi
fi

"$SELF_DIR/kb-index.sh" >/dev/null
INDEX_STATUS="OK"

echo "[kb-dont-repeat] checklist:"
echo "  capture:  $CAPTURE_STATUS ($CATEGORY/$SLUG)"
echo "  mistakes: $MISTAKES_STATUS"
echo "  triage:   $TRIAGE_STATUS"
echo "  index:    $INDEX_STATUS"
