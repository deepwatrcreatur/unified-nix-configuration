# 10 Den Legacy Inventory Reduction

Status: `ready`

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
