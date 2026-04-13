# 17 Agent Mail Workflow Fit

Status: `done`

Suggested branch: `docs/tooling-agent-mail-fit`

## Goal

Evaluate whether any subset of Agent Mail should be adopted in this repo without
accidentally fighting the repo's existing worktree-and-PR workflow.

## Why

Agent Flywheel treats Agent Mail, beads, and bv as one coordination stack, and
its guidance explicitly favors many agents working in one shared checkout. This
repo does not currently operate that way. Repo guidance in
[`AGENTS.md`](../../AGENTS.md), [`README.md`](../../README.md), and
[`agent-guides/worktrunk.md`](../../agent-guides/worktrunk.md) standardizes on
`wt`/worktrees and PR-scoped branches.

So the useful question is not "install Agent Mail because the website likes
it." The useful question is whether there is a narrow, compatible subset worth
adopting here, or whether the correct decision is to reject it until the
operating model changes.

## Scope

- document the direct workflow conflicts between Agent Mail's shared-branch
  model and this repo's current worktree model
- evaluate narrow features independently from the full Flywheel stack:
  - advisory file reservations
  - explicit inbox/handoff messaging
  - lightweight identity for parallel agents
- determine whether any of those features provide value even when agents work in
  separate worktrees
- leave a clear recommendation:
  - reject for now
  - prototype narrowly
  - adopt more fully after a workflow change

## Non-Goals

- moving this repo to "all agents commit directly to main"
- replacing the existing queue with Agent Mail
- debating multi-agent swarms in the abstract without grounding it in this repo

## Implementation (current)

- `docs/agent-mail-workflow-fit.md` records a repo-specific evaluation
  of Agent Mail against the existing `wt`/worktree and PR-first
  workflow.
- The decision is to **not adopt Agent Mail** for the current model,
  with rationale for why the shared-branch assumptions conflict with the
  repo's conventions.
- Narrow features (reservations, inboxes, identity) are considered and
  rejected as either redundant or low-value on top of existing queues,
  worktrees, and docs. Future adoption would require an explicit
  migration plan.

## Validation

- the final document states an explicit decision and reasoning
- the recommendation references current repo workflow constraints directly
- if a narrow prototype is recommended, it is small enough to fit in one follow-up PR
