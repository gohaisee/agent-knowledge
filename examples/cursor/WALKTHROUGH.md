# Cursor setup walkthrough

~5 minutes to wire agent-knowledge into a project opened in Cursor.

## 1. Install the toolkit

```bash
git clone https://github.com/gohaisee/agent-knowledge.git /tmp/agent-knowledge
cp -R /tmp/agent-knowledge/. /your-repo/.knowledge/
cd /your-repo
.knowledge/setup/install.sh
.knowledge/bin/kb-index.sh
```

## 2. Copy hook config

```bash
mkdir -p .cursor
cp .knowledge/examples/cursor/hooks.json .cursor/hooks.json
```

Edit paths if your folder is not `.knowledge`:

```json
"command": "bash .knowledge/hooks/kb-recall.sh"
```

For **worktrees / CLI outside the project root**, use absolute paths in `~/.cursor/hooks.json`:

```json
"command": "bash /full/path/to/.knowledge/hooks/kb-recall.sh"
```

## 3. Optional: governance rule

```bash
cp .knowledge/examples/cursor/rules/knowledge-governance.mdc .cursor/rules/
```

Fix the path to `GOVERNANCE.md` inside the rule if needed.

## 4. Verify hooks run

1. Reload Cursor window (or open a new Agent chat).
2. Ask something that matches a demo note, e.g. *"Should we force push to main?"*
3. The agent should already know about [[git-no-force-push]] — injected by `kb-recall` before the model answers.

Manual check:

```bash
echo '{"prompt":"force push to main branch"}' | .knowledge/hooks/kb-recall.sh | python3 -m json.tool | head
```

You should see `additional_context` with ranked kb notes.

## 5. Fill `kb/` with your project

Replace demo notes (`source: demo`) with real rules and architecture. Run:

```bash
.knowledge/bin/kb-validate.sh
.knowledge/bin/kb-index.sh
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| No injected context | Hooks path wrong; check `.cursor/hooks.json` |
| Empty search | Run `kb-index.sh`; `kb.db` must exist |
| Stale notes | `kb-index.sh` after editing `kb/` |

See also: [setup/SETUP.md](../../setup/SETUP.md) · [GOVERNANCE.md](../../GOVERNANCE.md)
