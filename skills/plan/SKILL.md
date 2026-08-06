---
name: plan
description: Turn an agreed direction into ordered, independently shippable steps before any code is written.
---

# Plan

`/brainstorm` settles what to build. This settles the order.

1. Break the work into steps that each **end in a commit that could ship on its
   own**. A step that leaves the tree broken is two steps.
2. Order by what is hard to reverse: schema, contracts and interfaces before the
   code that uses them. Cheap-to-change work goes last, where the answers are
   better.
3. Name the test that proves each step. A step with no test is a spike, or it is
   not a step.
4. Write what you do **not** know as questions, never as assumptions. An
   assumption in a plan is discovered in step 6.
5. Put the plan where this repo puts design work. Check its `AGENTS.md`.

Show it and get agreement. Do not start step 1 while writing it.

Once agreed, `/iterate`.

$ARGUMENTS
