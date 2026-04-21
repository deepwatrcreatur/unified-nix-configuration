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

If `beads-rust` is available and `.beads/issues.jsonl` exists, use
`beads-rust ready --labels router --json` as the primary queue surface. Otherwise,
fall back to the ordered list in [`README.md`](./README.md).

## How To Choose Work

0. Refresh remote state first if multiple agents may be active (`git fetch origin`).
1. Start with the ordered list in [`README.md`](./README.md).
2. Find the first item whose header says `Status: ready`.
3. Before taking it, check whether the suggested branch/worktree already
   appears to exist.
4. If the suggested branch/worktree exists, do not treat that alone as active
   ownership. Check for evidence such as:
   - a recent commit on the branch
   - an open PR tied to the task
   - the task file already marked `in-progress`
5. If the branch/worktree exists but there is no clear evidence of active
   ownership, treat it as stale and continue with the task.
6. Once you take an item:
   - create/switch to the suggested branch
   - update that work-item file header from `ready` to `in-progress`
   - commit and push that claim promptly if the queue is shared through git
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
active owner. Existing branches/worktrees are a hint, not a lock.

## Required Constraints

Preserve these unless the work item explicitly says otherwise:

- shared production router identity
- distinct management identities
- standby/dev use with production NICs unplugged must remain supported
- management plane must remain the recovery path

## Current High-Value Order

Use the ordered list in [`README.md`](./README.md). Do not duplicate or edit a
second ranked list in this file; `README.md` is the authoritative queue.

## Fast Start

If you want the shortest path:

- pick the next available item from the ordered list
- use the matching prompt from [`agent-prompts.md`](./agent-prompts.md)
- update the selected file to `Status: in-progress`
- implement and validate

## PR Workflow

The normal end state for a work item is a PR, not an unreviewed direct merge.

Recommended loop:

1. implement and validate locally
2. push the branch and open a PR
3. wait briefly for CI and bot review to appear
4. read GitHub comments and checks
5. fix substantive issues
6. merge only after checks are green or remaining comments are intentionally
   judged non-blocking

Do not skip the “read comments after a few minutes” step when bot review is
part of the project workflow.

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
