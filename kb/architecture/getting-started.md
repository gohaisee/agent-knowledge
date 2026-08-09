---
id: getting-started
category: architecture
service: "*"
severity: info
tags: [onboarding, setup]
created: 2026-08-09
source: template
---

# How to use agent-knowledge

1. Put this folder in your repo root (as `.knowledge` or `agent-knowledge/`).
2. Run `bin/kb-index.sh` to build the index.
3. Wire up hooks from `examples/cursor/` or `examples/claude/`.
4. After substantial work — `kb-capture.sh` only for knowledge that's **actually new**.

**Why:** agents don't keep context between sessions; cheap FTS recall fixes that without a cloud service.

**How to apply:** read `GOVERNANCE.md` first; project rules live in `kb/rules/`.
