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

Do not `git push --force` to `main`, `master`, or any branch other people might pull from.

**Why:** force push rewrites history on the remote. Teammates with old commits get conflicts that are painful to untangle.

**How to apply:** use a normal push or a new branch. Force push only if the user explicitly asks and the branch is clearly theirs alone.

See also: [[capture-only-with-approval]].
