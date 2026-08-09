# Claude Code setup walkthrough

## 1. Install

```bash
git clone https://github.com/gohaisee/agent-knowledge.git /tmp/agent-knowledge
cp -R /tmp/agent-knowledge/. /your-repo/agent-knowledge/
cd /your-repo
agent-knowledge/bin/kb-index.sh
```

## 2. Merge hooks into `.claude/settings.json`

Copy hook blocks from `agent-knowledge/examples/claude/settings.json` into your project’s `.claude/settings.json`.

Paths should point to `agent-knowledge/hooks/` (or `.knowledge/hooks/` if you renamed the folder).

## 3. Session flow

- **SessionStart** — short memory wake-up + top rules
- **UserPromptSubmit** — `kb-recall.sh` injects top FTS matches
- **Stop / SessionEnd** — capture reminder (does not write to kb automatically)

## 4. Verify

```bash
echo '{"prompt":"force push main"}' | agent-knowledge/hooks/kb-recall.sh
```

## 5. Optional Claude memory

Index Claude’s project memory alongside `kb/`:

```bash
export KB_MEMORY_DIR="$HOME/.claude/projects/-Users-you-yourproject/memory"
agent-knowledge/bin/kb-index.sh
```

See [setup/SETUP.md](../../setup/SETUP.md) for details.
