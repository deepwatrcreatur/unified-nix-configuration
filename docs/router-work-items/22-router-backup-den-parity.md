# Router-Backup Den Parity

Status: `done`
Priority: `medium`
Branch: `refactor/router-backup-den-parity`

## Goal

Apply the same den/legacy boundary cleanup to `router-backup` after the main
router leaf is better understood.

## Why

`router-backup` is still a hybrid den leaf with imports from:

- `hosts/nixos/router-backup/hardware-configuration.nix`
- `hosts/nixos/router-backup/networking.nix`
- `hosts/nixos/router-backup/caddy.nix`
- `hosts/nixos/router-backup/configuration.nix`

It should not drift into a different organizational model than `router`.

## Scope

- compare `den/hosts/router/default.nix` and `den/hosts/router-backup/default.nix`
- keep only the differences that are truly backup-specific
- mirror any den-boundary cleanup already done for `router`
- add comments if any remaining legacy imports are intentionally kept

## Constraints

- preserve `router-backup` behavior exactly
- do not merge this before understanding the active `router` boundary
- keep the PR focused on parity and ownership, not new router features

## Validation

- `nix build .#nixosConfigurations.router-backup.config.system.build.toplevel`
- compare active import structure against `router`
- confirm the remaining differences are host-specific and not accidental drift

## Outcome

Building on item 21 (which inlined `networking.nix` and added per-import comments),
this PR removes the remaining single-line passthrough wrapper:

- Deleted `hosts/nixos/router-backup/caddy.nix` (`import ../router/caddy.nix`)
- Updated `den/hosts/router-backup/default.nix` to import `router/caddy.nix` directly
- Fixed the comment (was "large, host-local"; clarified it's the shared Caddy config)

Remaining `extraImports` that differ from `router` are all intentionally backup-specific:
- `hardware-configuration.nix` — different physical hardware
- `router/networking.nix` — shared config with hostname override inline in den leaf
- `router/caddy.nix` — same shared Caddy config, now imported directly
- `configuration.nix` — backup-specific args: different WAN/LAN devices, separate
  Grafana/Prometheus paths, `enableLogStorage=false`

Validated: `nix eval .#nixosConfigurations.router-backup.config.networking.hostName`
→ `"router-backup"` and `.config.services.caddy.enable` → `true`.
