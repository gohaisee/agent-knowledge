# Capture template after hotfix / incident

```bash
echo "$(cat <<'EOF'
## Symptom
What the user or monitoring saw.

## Root cause
The mechanism — not just "bug in code".

## Fix
What we changed, before/after.

## How to apply
Checklist for the agent next time.
EOF
)" | bin/kb-capture.sh errors <slug-kebab> "<title>" hotfix <component>
```

Session exit "don't repeat" — `bin/kb-dont-repeat.sh` (template `dont-repeat-capture.md`).
