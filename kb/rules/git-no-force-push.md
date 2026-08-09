---
id: git-no-force-push
category: rules
service: "*"
severity: hard
tags: [git, workflow, safety]
created: 2026-08-09
source: demo
---

# Never force-push shared branches

Do not `git push --force` to `main`, `master`, or any branch teammates might pull.

**Why:** force push rewrites remote history. People with old commits get a mess that's hard to unwind.

**How to apply:** use a normal push or a new branch. Force push only if the user explicitly asks and the branch is clearly theirs alone. Even when push is allowed ([[capture-only-with-approval]]), shared branches stay no-force-push.

See also: [[capture-only-with-approval]].
