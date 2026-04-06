# Router Leaf Inline Migration

Status: `done`
Priority: `medium`
Branch: `refactor/router-leaf-inline-migration`

## Goal

Reduce the number of legacy router file imports in `den/hosts/router/default.nix`
by moving simple host-local composition directly into the den leaf.

## Why

Right now the router den leaf still imports several legacy files:

- `hardware-configuration.nix`
- `networking.nix`
- `caddy.nix`
- `disko.nix`
- `configuration.nix`

Some of these may still make sense as imports, but some are only thin
composition wrappers and can likely be inlined or split more cleanly.

## Target Scope

Start with the non-hardware pieces only.

Good candidates:

- identify whether `configuration.nix` is mostly wiring around
  `hosts/nixos/router/role.nix`
- identify whether `networking.nix` is host-local data or reusable logic
- identify whether `caddy.nix` is truly host-local enough to stay separate

The desired outcome is:

- `den/hosts/router/default.nix` remains the obvious active leaf
- thin legacy wrapper files are reduced
- large behavioral modules stay where they belong

## Constraints

- keep `hardware-configuration.nix` imported as-is
- do not change router behavior
- prefer moving only one or two imports per PR if the diff grows

## Validation

- `nix build .#nixosConfigurations.router.config.system.build.toplevel`
- confirm resulting router output is equivalent at a high level
- ensure comments explain any remaining legacy imports that are still
  intentional

## Outcome

- Added per-import comments to `den/hosts/router/default.nix` explaining
  why each legacy file is kept separate (hardware-adjacent, large host-local,
  or still uses topology config).
- Inlined `hosts/nixos/router-backup/networking.nix` into
  `den/hosts/router-backup/default.nix`. That file was a 7-line thin wrapper
  that set `networking.hostName = "router-backup"` and imported
  `router/networking.nix`. The hostname override is now inline; the wrapper
  is deleted.
- Validated: `nix eval .#nixosConfigurations.router.config.networking.hostName`
  → `"router"` and `.#nixosConfigurations.router-backup.config.networking.hostName`
  → `"router-backup"`.
