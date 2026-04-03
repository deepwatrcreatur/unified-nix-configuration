# Router Agent Start Here

If you are a coding agent starting router follow-up work in this repo, follow
this file and it should be enough to begin contributing.

## Objective

Pick the next highest-value router work item that is not already in progress,
do it in its own worktree/branch, and keep the work scoped to one PR.

## Where The Work Queue Lives

Read first:

- [`README.md`](./README.md)
- [`agent-prompts.md`](./agent-prompts.md)

The authoritative work queue is the ordered list in [`README.md`](./README.md).

## How To Choose Work

1. Start with the ordered list in [`README.md`](./README.md).
2. Find the first item whose header says `Status: ready`.
3. Before taking it, check whether the suggested branch/worktree already
   appears to exist.
4. If the suggested branch/worktree already exists, assume another agent may
   already own it and skip to the next `ready` item unless the file header
   clearly says otherwise.
5. Once you take an item:
   - create/switch to the suggested branch
   - update that work-item file header from `ready` to `in-progress`
   - make only the changes needed for that item

## Ownership Rules

- one work item per branch
- one agent per work item unless a human explicitly says otherwise
- do not mix unrelated refactors into the same branch

## Source Of Truth

Use both:

- primary: work-item file status header
- secondary: existing branch/worktree presence

Do not rely only on worktrees, because a stale worktree may exist without an
active owner.

## Required Constraints

Preserve these unless the work item explicitly says otherwise:

- shared production router identity
- distinct management identities
- standby/dev use with production NICs unplugged must remain supported
- management plane must remain the recovery path

## Current High-Value Order

1. [`01-router-recovery-invariants.md`](./01-router-recovery-invariants.md)
2. [`02-stable-interface-matching.md`](./02-stable-interface-matching.md)
3. [`03-management-plane-independence.md`](./03-management-plane-independence.md)
4. [`04-service-dependency-cleanup.md`](./04-service-dependency-cleanup.md)
5. [`05-router-health-model.md`](./05-router-health-model.md)
6. [`06-boot-and-recovery-hardening.md`](./06-boot-and-recovery-hardening.md)
7. [`07-observability-and-flow-logging.md`](./07-observability-and-flow-logging.md)
8. [`08-vlans-and-vpn-policy-routing.md`](./08-vlans-and-vpn-policy-routing.md)

## Fast Start

If you want the shortest path:

- pick the next available item from the ordered list
- use the matching prompt from [`agent-prompts.md`](./agent-prompts.md)
- update the selected file to `Status: in-progress`
- implement and validate

## When To Use GitHub Issues Instead

Do not create a GitHub issue for a narrow implementation task that already has
one work-item file here.

Use GitHub issues only when:

- the task needs human discussion
- the task spans multiple PRs or repos
- prioritization is unclear
- the work item here is no longer sufficient and needs a broader conversation

## Completion Rules

When your PR merges:

- update the work-item file to `done` or delete it if the work is fully
  complete and no longer useful
- if partial work remains, leave a smaller follow-up file behind instead of
  keeping stale completed text
