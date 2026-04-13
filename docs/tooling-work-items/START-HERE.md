# Tooling Agent Start Here

If you are a coding agent starting repo-tooling work in this repo, follow this
file and it should be enough to begin contributing.

## Objective

Pick the next highest-value tooling work item that is not already in progress,
do it in its own worktree/branch, and keep the work scoped to one PR.

## Where The Work Queue Lives

Read first:

- [`README.md`](./README.md)
- [`agent-prompts.md`](./agent-prompts.md)

If `br` is available and `.beads/issues.jsonl` exists, use
`br ready --labels tooling --json` as the primary queue surface. Otherwise,
fall back to the ordered list in [`README.md`](./README.md).

## How To Choose Work

0. Refresh remote state first if multiple agents may be active (`git fetch origin`).
1. Start with the ordered list in [`README.md`](./README.md).
2. Find the first item whose header says `Status: ready`.
3. Before taking it, check whether the suggested branch/worktree already exists.
4. If a branch/worktree exists but there is no sign of active ownership
   (recent commits, open PR, or file already marked `in-progress`), treat it as
   stale and proceed.
5. Mark the item `in-progress` in your branch as part of the same PR.

## Invariants

- Do not wrap build/orchestration commands just because wrapping is possible.
- Prefer wrapping commands that regularly need secrets or policy defaults.
- Preserve canonical command names only when the wrapped variant is already
  established as the better default.
- Keep raw tools available when the wrapped command is a convenience layer, not
  a true replacement.
- Follow the existing fallback pattern where possible:
  `if pkgs ? <tool>-fnox then <tool>-fnox else <tool>`.

## PR Workflow

1. Validate locally as appropriate.
2. Push your branch and open a PR.
3. Wait briefly for CI and bot review.
4. Read comments and fix substantive issues.
5. Merge only after checks are green or remaining comments are intentionally
   judged non-blocking.

## Completion Rules

When your PR merges:

- update the work-item file to `done` or delete it if the work is fully
  complete and no longer useful
- if partial work remains, leave a smaller follow-up file behind instead of
  keeping stale completed text
