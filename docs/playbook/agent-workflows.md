# Procedure: Parallel Agent Workflows

**Context**: Multiple agents working on the same repository simultaneously.

## Strategy: Dedicated Worktrees

Standardize on one worktree per major task to avoid lock contention and local
state drift.

1. **Create Worktree**:
   ```bash
   rtk wt add ~/flakes/unified-nix-configuration-task-name -b feat/task-name origin/main
   ```
2. **Isolate State**: Avoid sharing `.direnv` or `result` links between worktrees.
3. **Commit Early**: Push to origin frequently so other agents can see your progress.

## Identity and Handoff

- Always mark your task as `in-progress` in `README.md` immediately.
- Update the work-item file with "Implementation Notes" upon completion.
- Link relevant PRs in the work-item file.

## Anti-Patterns

- **Shared Main**: Don't work directly on `main` branch.
- **Hidden State**: Don't leave critical logic in uncommitted files for long.
- **Blind Fixes**: Don't "fix" hashes or paths without verifying WHY they failed first (e.g. Caddy source drift).
