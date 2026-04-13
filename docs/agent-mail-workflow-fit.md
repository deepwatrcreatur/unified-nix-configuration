# Agent Mail Workflow Fit

This document evaluates whether Agent Mail (from the Agent Flywheel stack)
should be adopted in this repo, given its existing worktree- and
PR-centric workflow.

## Summary Decision

For the current operating model, this repo **does not adopt Agent Mail**.

- The core Agent Mail workflow assumes many agents working in a shared
  checkout and shared branches.
- This repo standardizes on `wt`/worktrees, one work item per branch,
  and PR-scoped review.
- The potential narrow features (advisory reservations, inboxes,
  lightweight identity) do not provide enough incremental value on top of
  the existing queues, worktrees, and docs to justify the added
  complexity.

If the workflow changes in the future (e.g., moving to a
shared-checkout-first model), this decision can be revisited.

## Current Repo Workflow

Key pieces of the current model:

- **Worktrees and branches**
  - Worktrunk (`wt`) is the standard tool for managing worktrees.
  - Each work item gets its own branch and worktree when appropriate.
  - Branches are short-lived and scoped to one PR-sized task.
- **Queues and docs**
  - Router and tooling queues live in `docs/router-work-items/` and
    `docs/tooling-work-items/`.
  - Handoff plans and design docs capture longer-lived context.
- **Review and integration**
  - GitHub PRs are the primary integration path.
  - Direct commits to `main` are rare and generally avoided for
    multi-step work.

This model is intentionally different from Agent Flywheel's
"many agents on one shared checkout" assumption.

## Conflicts with Agent Mail's Shared-Branch Model

Agent Flywheel and Agent Mail assume:

- many agents operate on the same branch (often `main` or a long-lived
  feature branch)
- coordination happens via reservations and inboxes layered over that
  shared branch

In this repo, that would conflict with:

- the desire to keep agent work isolated per branch/worktree
- the expectation that branches correspond closely to PRs
- the goal of keeping `main` stable and CI-friendly

Trying to layer Agent Mail's reservation and inbox semantics on top of a
per-branch worktree model would either:

- fight the existing conventions, or
- require a substantial amount of adapter code and documentation to
  avoid confusion.

## Evaluation of Narrow Features

### Advisory file reservations

Agent Mail's file reservations make the most sense when many agents are
pushing to the same branch. In this repo:

- concurrent edits are usually separated by branch/worktree
- conflicts are resolved through normal PR review and git merges

Conclusion: **not worth adopting** reservations on top of the existing
branch-per-task model.

### Explicit inbox/handoff messaging

This repo already has several handoff and coordination surfaces:

- queue docs in `docs/router-work-items/` and `docs/tooling-work-items/`
- handoff plans such as `docs/agent-handoff-plan-*.md`
- AGENT entrypoints (`AGENTS.md`, `RTK.md`) and per-agent docs

Adding an Agent Mail inbox layer would duplicate much of this and risk
confusion about the "real" source of truth.

Conclusion: **keep using doc- and PR-based handoff**; do not add an
Agent Mail inbox at this time.

### Lightweight identity for parallel agents

This repo already uses:

- branch names and worktrees as the primary unit of agent ownership
- queue docs and work items with `Status: ready/in-progress/done`
- GitHub PRs and commit history

Agent Mail's additional identity layer does not solve a pressing gap
here.

Conclusion: **no immediate need** for Agent Mail's identity model beyond
what branches, worktrees, and docs already provide.

## Recommendation

- **Decision**: do **not** adopt Agent Mail for this repo's current
  workflow.
- **Reasoning**: the core value proposition (shared-branch coordination)
  conflicts with a worktree- and PR-first model, and the narrow
  sub-features are either redundant with existing practices or provide
  limited extra value.
- **Future guardrail**: if a future change proposes adopting Agent Mail
  or a similar system, it should come with an explicit migration plan
  for how it interacts with `wt`, worktrees, and the existing
  queue/PR-based workflow.
