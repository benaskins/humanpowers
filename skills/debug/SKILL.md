---
name: debug
description: Use when diagnosing bugs, test failures, or unexpected behavior. Requires hypotheses before fixes — no jumping to solutions.
---

# Debug

1. Reproduce the user's exact experience — same protocol, same URL, same path.
2. Form 3 hypotheses ranked by likelihood. Start boring: config, typos, cached state, stale build.
3. Run one cheap check per hypothesis. Share what you found before proposing a fix.

If your approach fails twice, stop and reassess — you're missing context, not cleverness.

$ARGUMENTS
