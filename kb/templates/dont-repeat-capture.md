# Session exit "don't repeat" template (mistakes required)

Don't use plain `kb-capture` for retros / "I hit this again".

```bash
echo "$(cat <<'EOF'
Short bullet: what to check or avoid (1–3 sentences).
EOF
)" | bin/kb-dont-repeat.sh \
  --slug <slug-kebab> \
  --title "<short title for checklist>" \
  --category errors \
  --triage-row "log symptom|verdict|action [[slug]]" \
  ci
```

Before running: `kb-search.sh "<topic>"` — make sure it's not already there.

Exit checklist:
- [ ] `mistakes: OK` in script output
- [ ] for CI — `triage: OK` or `exists`
- [ ] `index: OK`
