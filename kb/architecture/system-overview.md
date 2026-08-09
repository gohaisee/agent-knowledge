---
id: system-overview
category: architecture
service: "*"
severity: info
tags: [onboarding, architecture, demo]
created: 2026-08-09
source: demo
---

# System overview (demo)

This repo is the knowledge layer, not the app itself. Your product code lives elsewhere; this folder holds notes the agent recalls between sessions.

**Pieces:** `kb/` (markdown notes) · `bin/` (index, search, capture) · `hooks/` (inject context into Cursor or Claude) · `kb.db` (local FTS index, rebuilt from `kb/`).

**Flow:** edit or capture a note → `kb-index.sh` → hooks run `kb-search.sh` on each prompt → top matches land in agent context.

**How to apply:** when onboarding a new repo, copy or submodule this toolkit, wire hooks from `examples/`, then fill `kb/rules/` and `kb/architecture/` with your project facts.

See also: [[getting-started]] · [[stub-example-api]].
