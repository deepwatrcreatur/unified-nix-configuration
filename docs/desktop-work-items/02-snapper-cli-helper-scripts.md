# 02 Snapper CLI Interactive Helper Scripts

Status: `ready`
Suggested branch: `feat/snapper-helper-scripts`
Priority: `medium`

## Goal

Provide user-friendly, interactive CLI scripts for Btrfs snapshot creation and retention management with Snapper: `snap-create-home`, `snap-create-root`, `snap-lock`, and `snap-unlock`.

## Why

Managing Btrfs snapshots with raw `snapper` commands requires remembering subvolume config names and flags (`-c ""`, `-c "timeline"`). Having interactive, dedicated CLI helpers in `$PATH` makes taking manual pre-maintenance snapshots and locking snapshots from automatic timeline deletion trivial.

## Scope

1. Define helper scripts in `modules/nixos/snapper.nix` (or a dedicated snapper aspect):
   - `_snap-create <config>`: Prompts for snapshot description and an optional lock prompt (setting cleanup to `""` if locked or `"timeline"` if auto-deleted).
   - `snap-create-home`: Wrapper executing `_snap-create home`.
   - `snap-create-root`: Wrapper executing `_snap-create root`.
   - `snap-lock`: Prompts for config (home vs. root), lists existing snapshots, prompts for Snapshot ID, and sets `-c ""` to lock from cleanup.
   - `snap-unlock`: Prompts for config, lists snapshots, prompts for Snapshot ID, and sets `-c "timeline"` to allow automatic rotation.
2. Add `btrfs-assistant` package to system packages when snapper is enabled.
3. Expose the scripts in system packages or home manager packages.

## Validation

- `nix eval .#nixosConfigurations.phoenix.config.environment.systemPackages` includes `snap-create-home`, `snap-create-root`, `snap-lock`, and `snap-unlock`.
- Flake checks succeed.
