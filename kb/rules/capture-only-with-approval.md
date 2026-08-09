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

Commit, push, open MR/PR — only when the user explicitly asked for that git action.

**Why:** the agent shouldn't push unchecked code or touch remotes on its own initiative.

**How to apply:** before `git commit`, `git push`, or opening a PR — check the request actually asked for it. This rule is about *permission*, not which git flags to use.

See also: [[git-no-force-push]] (separate rule: never force-push shared branches even when push is allowed).
