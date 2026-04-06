# 10 Den Legacy Inventory Reduction

Status: `done`

Suggested branch: `refactor/tooling-den-legacy-inventory`

## Goal

Reduce the number of `den/inventory` entries that still use `mode = "legacy"`
when the surrounding repo structure now treats `den` as the primary inventory
layer.

## Why

Several non-router areas are still marked legacy in `den/inventory`, including:

- `den/inventory/homes.nix` for proxmox-root home outputs
- `den/inventory/darwin.nix`
- `den/inventory/bootstrap.nix`

That may be justified in some cases, but the current boundary is not explicit
enough. Future agents will have a hard time telling whether these are
intentionally legacy or simply not migrated yet.

## Scope

- audit each remaining `mode = "legacy"` inventory entry outside the router
  path
- classify them as:
  - intentionally legacy and should stay that way for now
  - ready for den-native cleanup
  - blocked by some missing framework capability
- add comments or small refactors that make the status of each entry explicit

## Non-Goals

- migrating the entire Darwin stack in one PR
- changing host behavior just to remove a `legacy` label
- duplicating the router migration queue

## Validation

- den docs and inventory make the remaining legacy boundaries easier to follow
- any changed outputs still evaluate cleanly
- future agents can tell which legacy inventory entries are intentional

## Outcome

Audited all three non-router legacy inventory files. All are **intentionally
legacy** for different structural reasons:

- `bootstrap.nix` (`nixos_lxc_without_determinate`, `nixos_lxc_with_determinate`):
  `kind = "special"` — these are NOT processed by `mkInventoryOutputs`. Their
  actual NixOS outputs live in `outputs/nixos-lxc.nix`. Legacy by design because
  the bootstrap sequence deliberately omits Determinate Nix in step 1.

- `darwin.nix` (`hackintosh`, `macminim4`): consumed by `mkDarwinOutput` but
  legacy because no darwin aspects exist in `den/aspects/`. `hackintosh` is also
  absent from `lib/hosts.nix` (likely inactive). `macminim4` is active; can be
  migrated once darwin-specific aspects are defined.

- `homes.nix` (proxmox-root homes): consumed by `mkHomeOutput` but legacy
  because the den framework has no home-manager aspect concept. The proxmox-root
  profile is stable and small; no migration planned.

Added explanatory comments to each file making the intentional/blocked status
explicit so future agents stop debating whether to migrate them.
