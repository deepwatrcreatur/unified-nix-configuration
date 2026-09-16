# Host Migration Agent Start Here

If you are a coding agent starting host naming or role migration work in this repo, follow this file to begin contributing.

## Objective

Pick the next highest-priority host migration work item that is `ready` and not already `in-progress`, execute it in its own worktree/branch, and keep the work strictly scoped to one PR.

## Where The Work Queue Lives

Read first:

- [`README.md`](./README.md)
- [`../host-naming-and-dendritic-role-migration-plan.md`](../host-naming-and-dendritic-role-migration-plan.md)

If `beads-rust` is available and `.beads/issues.jsonl` exists, you can also inspect `beads-rust ready --label host-migration`.

## Workflow Rules

1. **One Host / Work Item per PR**:
   Never combine multiple host migrations into a single PR. Migrating a host touches agenix keys, inventory consistency checks, DNS CNAMEs, and SSH blocks. Keeping PRs isolated makes bot and human review clean and predictable.
2. **Always Run Checks Locally Before Pushing**:
   ```bash
   nix build .#checks.x86_64-linux.inventory-consistency --no-link
   nix build .#checks.x86_64-linux.module-loading-eval --no-link
   nix build .#checks.x86_64-linux.ssh-keys-manager-eval --no-link
   ```
3. **Agenix Rekeying**:
   If a host identity is renamed in `secrets.nix`, run `just rekey` and verify no zero-byte `.age` files are produced.
4. **Worktree Isolation**:
   Always branch from clean `origin/main` in a dedicated worktree under `flakes-worktrees/unified-nix-configuration/<branch-name>`.
