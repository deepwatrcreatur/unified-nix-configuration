# Checkout Strategies

This repo supports two valid ways for agents to work:

- a shared checkout
- separate worktrees, usually managed with `wt`

Neither is universally correct. Pick the model that matches the shape of the
work.

## Default Rule

Use a shared checkout when the work is sequential, tightly coupled, or mostly
read-only.

Use separate worktrees when multiple agents may edit overlapping parts of the
repo at the same time, or when the work should land as isolated PRs.

## Shared Checkout Is Better When

- one agent is doing the work end to end
- the task is exploratory, investigative, or documentation-heavy
- several edits need to stay tightly synchronized and would be awkward to split
  across branches
- you are iterating quickly on one local change and do not want worktree
  management overhead
- the coordination mechanism is conversational rather than branch-based

## Worktrees Are Better When

- multiple agents are active in parallel
- each work stream should produce its own branch or PR
- there is real risk of two agents editing the same files or rebasing over each
  other
- one agent needs to continue safely while another experiments
- you want a clean ownership boundary for validation and rollback

## Repo-Specific Guidance

Today, this repo's queue and review workflow are still branch-oriented:

- [`docs/tooling-work-items/README.md`](../docs/tooling-work-items/README.md)
- [`docs/router-work-items/README.md`](../docs/router-work-items/README.md)
- [`AGENTS.md`](../AGENTS.md)

That means worktrees are still the safer default for parallel implementation
work that is expected to merge through PRs.

At the same time, a shared checkout is reasonable for:

- local research or audits
- one-agent docs work
- short-lived experiments that are not being delegated in parallel
- situations where worktree splitting adds more friction than safety

## What This Repo Is Not Doing Yet

This repo is not currently standardized on a shared-checkout Agent Mail model
where many agents commit directly into one branch. If that changes, this guide
should be updated and the branch-oriented queue docs should change with it.

Until then:

- do not assume shared checkout coordination primitives exist
- do not assume an existing worktree is a hard lock
- do treat branch/worktree ownership as the primary safety boundary for parallel
  implementation work

## Practical Decision Rule

Ask these questions in order:

1. Will more than one agent write code at the same time?
   If yes, prefer worktrees.
2. Does the work need a separate PR or isolated rollback path?
   If yes, prefer worktrees.
3. Is the task mostly analysis, docs, or one-agent implementation?
   If yes, a shared checkout is fine.
4. Are you forcing worktrees out of habit even though no isolation benefit is
   being gained?
   If yes, stay in the shared checkout.

## Worktree Quickstart

If you choose worktrees, use [`worktrunk.md`](./worktrunk.md):

- `wt list`
- `wt switch -c feat/my-change`
- `wt switch feat/my-change`
- `wt remove`
