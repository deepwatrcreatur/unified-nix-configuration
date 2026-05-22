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

If `beads-rust` is available and `.beads/issues.jsonl` exists, use
`beads-rust ready --label tooling --json` as the primary queue surface. If `bv` is
also available, use `bv --robot-triage --labels tooling --json` for
PageRank/critical-path ranked suggestions. Otherwise, fall back to the
ordered list in [`README.md`](./README.md).

## Robot Triage (bv)

`bv --robot-triage` scores each open bead by:
- **PageRank** — centrality in the dependency graph; high score = many tasks
  depend on this one
- **Critical-path pressure** — longest chain through this node; the item
  whose removal shortens the critical path the most

```bash
# JSON array, highest priority first (top 5):
bv --robot-triage --labels tooling --json | jq '.[0:5]'

# Interactive TUI for visual graph exploration:
bv
```

Scores are relative to the current graph state. A `pagerank_score` near 1.0
is maximally central; `critical_path_rank` 1 = the single most blocking task.
Use these as hints — human override via README ranking is always valid.

See [`../../docs/robot-triage.md`](../../docs/robot-triage.md) for full
interpretation guidance.

## How To Choose Work

0. Refresh remote state first if multiple agents may be active (`git fetch origin`).
1. **Preferred** (when `.beads/` is populated):
   `bv --robot-triage --labels tooling --json | jq -r '.[0].title'`
2. **Fallback**: the ordered list in [`README.md`](./README.md); find the
   first item whose header says `Status: ready`.
3. Before taking it, check whether the suggested branch/worktree already exists.
4. If a branch/worktree exists but there is no sign of active ownership
   (recent commits, open PR, or file already marked `in-progress`), treat it as
   stale and proceed.
5. Mark the item `in-progress` in your branch as part of the same PR.
6. If the item touches a live host, treat that host as an exclusive deployment
   target and avoid parallel rebuild/restart work from other agent sessions.

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
