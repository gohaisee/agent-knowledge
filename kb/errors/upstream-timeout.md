---
id: upstream-timeout
category: errors
service: example-api
severity: info
tags: [demo, timeouts, http]
created: 2026-08-09
source: demo
---

# Upstream timeouts — fail visibly

When an upstream HTTP call times out, return a clear error to the caller instead of hanging or returning empty data.

**Why:** silent timeouts look like "no data" in the UI and waste hours debugging the wrong layer.

**How to apply:** set explicit client timeouts, log the dependency name and latency, surface `503` or a domain error with context. Retry only where idempotency is safe.

See also: [[stub-example-api]].
