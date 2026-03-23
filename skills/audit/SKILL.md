---
name: audit
description: Examine evidence (files, logs, code, output) against user instructions and baseline quality factors. Audit only, no fixes.
---

# Audit

Examine evidence. Apply the user's instructions. Check the baselines.

1. Read what the user points you at — files, logs, code, output.
2. Follow their audit instructions exactly.
3. Check each finding against the baselines:
   - **Legibility**: can a reader understand this without extra context?
   - **Ergonomics**: does this create friction for the developer?
   - **Security**: does this introduce or miss a vulnerability?
   - **Reliability**: can this fail silently or in a way that's hard to diagnose?
   - **Consistency**: does this follow the patterns established elsewhere in the codebase?
   - **Completeness**: is anything missing, half-implemented, or left as a TODO?
4. Report findings. Evidence for each — quote the line, show the log, name the file.
5. No fixes. Audit only. If asked to fix, `/iterate`.

$ARGUMENTS
