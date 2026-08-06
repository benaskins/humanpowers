---
name: deploy
description: Ship services one at a time, each confirmed serving before the next
---

# Deploy

Ship one service at a time. Do not start the next until this one is confirmed
serving.

1. **Find the project's own deploy path before running anything**: its
   `AGENTS.md`, its justfile or make targets, its CI workflow. Deploying by hand
   what CI deploys is how two deploys collide.
2. Confirm the tree is clean, and that the commit going out is the one you think
   it is.
3. Deploy the one service.
4. **Prove it serves.** Make a request against it. A process that started, a
   green pipeline, and a box that booted are all things that happen while
   nothing answers.
5. Only now, the next service.

If a step fails, stop and diagnose it. Do not deploy the next service around the
failure.

$ARGUMENTS
