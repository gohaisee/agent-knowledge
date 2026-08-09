# Installing agent-knowledge in a project

## Option A: `.knowledge` folder in the repo root

```bash
git clone https://github.com/<you>/agent-knowledge.git /tmp/agent-knowledge
cp -R /tmp/agent-knowledge/. /your-repo/.knowledge/
# or symlink: ln -s ../agent-knowledge /your-repo/.knowledge
```

## Option B: submodule

```bash
git submodule add https://github.com/<you>/agent-knowledge.git agent-knowledge
```

## Cursor

1. Copy `examples/cursor/hooks.json` → `.cursor/hooks.json`
2. Fix paths: `.knowledge/` or `agent-knowledge/`
3. Optional: rule `examples/cursor/rules/knowledge-governance.mdc` → `.cursor/rules/`
4. Worktree/CLI: `~/.cursor/hooks.json` with **absolute** paths to the hooks

## Claude Code

Merge `examples/claude/settings.json` into `.claude/settings.json`.

## First index

```bash
.knowledge/bin/kb-index.sh
.knowledge/bin/kb-search.sh "getting started"
```

## Optional: Claude memory

```bash
export KB_MEMORY_DIR="$HOME/.claude/projects/-Users-you-project/memory"
.knowledge/bin/kb-index.sh
```
