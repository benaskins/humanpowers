---
name: debug
description: Use when diagnosing bugs, test failures, or unexpected behavior. Requires hypotheses before fixes — no jumping to solutions.
---

# Debug

Diagnose before you fix. Hypotheses before changes. Boring explanations before clever ones.

1. Reproduce the user's exact experience — same protocol, same URL, same path
2. Read the error messages and logs before theorising
3. Form 3 hypotheses ranked by likelihood — start boring (config, typos, cached state)
4. Run one quick check per hypothesis, then share what you found
5. Only propose a fix after evidence points to a root cause
6. Apply the minimal fix, then `/verify`

If your approach fails twice, stop and reassess — you're missing context.

$ARGUMENTS
