# Agent Start Here

If you are a fresh coding agent entering this repo, read this file first.

It tells you how to get oriented before you start changing code.

## First Reads

Read these in order:

1. [`AGENTS.md`](../AGENTS.md)
2. [`README.md`](../README.md)
3. [`agent-guides/checkout-strategies.md`](./checkout-strategies.md)

After that, choose the task-specific path below.

## If You Are Taking Queue Work

Use the queue-specific start doc that matches the task area:

- router work:
  [`docs/router-work-items/START-HERE.md`](../docs/router-work-items/START-HERE.md)
- repo tooling work:
  [`docs/tooling-work-items/START-HERE.md`](../docs/tooling-work-items/START-HERE.md)

Those queue docs are still the authoritative onboarding flow for ranked backlog
work.

## If You Are Not Taking Queue Work

For ad hoc work, use this minimal checklist:

1. identify the host context with `hostname`
2. confirm whether the task should happen in a shared checkout or a worktree
3. inspect the relevant files before editing
4. keep changes scoped to the requested task
5. validate locally where practical

## How To Choose Checkout Mode

Use [`checkout-strategies.md`](./checkout-strategies.md):

- shared checkout: one-agent, sequential, research, docs, or tightly coupled work
- worktree: parallel implementation, separate PRs, or stronger isolation needs

## High-Signal Repo Entry Points

When you need more context, these are usually the next best reads:

- queue ranking:
  [`docs/router-work-items/README.md`](../docs/router-work-items/README.md),
  [`docs/tooling-work-items/README.md`](../docs/tooling-work-items/README.md)
- agent workflow notes:
  [`agent-guides/README.md`](./README.md)
- repo-wide Claude-oriented notes:
  [`CLAUDE.md`](../CLAUDE.md)

## Default Expectations

- do not assume worktrees are mandatory
- do not assume a shared checkout coordination layer exists
- treat queue status files and branch/worktree ownership as the source of truth
  for queued parallel implementation work
- prefer small, reviewable, task-scoped changes
