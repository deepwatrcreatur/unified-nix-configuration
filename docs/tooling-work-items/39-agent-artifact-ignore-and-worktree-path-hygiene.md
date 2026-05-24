# 39 Agent Artifact Ignore and Worktree Path Hygiene

Status: `ready`
Suggested branch: `chore/agent-artifact-ignore-hygiene`
Priority: `medium`

## Goal

Reduce status noise from local agent/editor artifacts and make external
worktree-path usage the boring default, so real hygiene violations stand out.

## Why

- Round 116 treated artifact clutter as a distinct but compounding problem:
  noisy `git status` output makes it harder to notice unsafe mutations.
- Recent cleanup in sibling repos already showed that ignoring obvious local
  agent/editor residue is low-risk and high-value.
- Worktree directories created inside repo trees also weaken the “is this
  checkout actually clean?” signal.

## Scope

1. Audit recurring local artifacts across the active repos and shell tooling,
   including agent metadata, editor sidecars, and recovery byproducts.
2. Add safe ignore coverage for clearly local-only artifacts that should never
   be reviewed or committed.
3. Tighten guidance and helpers so disposable worktrees are created outside the
   main repo tree by default.
4. Document the small cleanup workflow for when residue still appears.

## Non-Goals

- Ignoring real source files just because they are inconvenient
- Replacing the read-mostly policy or preflight guard
- Large-scale shell-environment redesign

## Validation

- Common agent/editor residue no longer appears as normal repo dirt.
- New worktree helpers default to paths outside the main checkout tree.
- `git status` in the shared checkout becomes a higher-signal indicator of real
  write activity.

## Notes

This work item should stay conservative: only ignore artifacts that are clearly
local/transient, and prefer explicit worktree-path defaults over broad ignore
patterns that could hide real mistakes.
