---
id: ci-triage-quick
category: rules
service: "*"
severity: hard
tags: [ci, triage]
created: 2026-08-09
source: template
---

# CI triage — quick lookup

| Log symptom | Verdict | Action |
|---|---|---|
| *(example)* test job red, no FAIL in log | flaky coverage | retry the job |

Add rows via `kb-dont-repeat.sh --triage-row "symptom|verdict|action"` or tags `ci`/`gitlab`/`oom`/`runner`.
