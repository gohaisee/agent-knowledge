---
id: capture-only-with-approval
category: rules
service: "*"
severity: hard
tags: [git, workflow]
created: 2026-08-09
source: template
---

# Git operations only when asked

Commit, push, MR/PR — only when the user explicitly asked for it.

**Why:** the agent shouldn't push unchecked code or mess up history.

**How to apply:** before any git command, confirm the request actually asked for it.
