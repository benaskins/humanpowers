---
name: deploy
description: Deploy one or more services end-to-end with health verification
---

# Deploy

Deploy one or more services end-to-end. Follow every step in order — do NOT proceed to the next service until the current one is verified healthy.

For EACH service:

1. Run `git status` in all affected repos — commit or stash any uncommitted changes
2. Build the binary
3. Install the binary to the target path
4. Stop existing processes and verify ports are free (check for stale processes)
5. Verify config paths match between daemon and traefik
6. Start the service
7. Run health check — `curl -s` against the health endpoint
8. Show output proving it works

Only move to the next service after the current one is confirmed healthy. If anything fails, diagnose and fix before proceeding.

$ARGUMENTS
