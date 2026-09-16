# 04 Router Role Boundary And Ruby Cutover

Status: `ready`
Suggested branch: `feat/ruby-router-migration`
Priority: `medium`
Depends on: `01-decouple-hostname-role-checks`, `02-attic-cache-to-emerald-migration`

## Goal

Migrate `router` and `router-backup` to `ruby` and `garnet`, updating router checks in `outputs/checks.nix` to use role lookups instead of hardcoded host keys.

## Scope

1. Generalize router checks in `outputs/checks.nix` to look up primary/backup by role or configured hostnames.
2. Update `modules/nixos/router/common.nix` and `hosts/nixos/router/dns-zone.nix` `@` record to reference the active router node.
3. Migrate `router` -> `ruby` (with aliases `router`, `dns`, `dhcp`, `firewall`, `router-management`) and `router-backup` -> `garnet`.
4. Rename agenix identities and rekey secrets with `just rekey`.
5. Run router smoke checks and full validation.

## Validation

- `nix build .#checks.x86_64-linux.inventory-consistency --no-link`
- `just router-smoke-check ruby`
