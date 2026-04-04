# Ulogd Plugin Mismatch Repair

Status: `done`
Priority: `high`
Branch: `fix/router-ulogd-plugin-mismatch`

## Goal

Make `ulogd.service` start reliably again on `router` and `router-backup`
 without causing `nixos-rebuild switch` to fail during otherwise healthy router
 updates.

## Why

Recent router rebuilds still fail with:

- missing `ulogd_output_JSON.so`
- `can't find requested plugin BASE`
- `not even a single working plugin stack`

That means the current `ulogd` configuration no longer matches the plugin set
shipped by the packaged `ulogd` build in Nixpkgs. This is now a concrete
runtime failure, not a speculative observability enhancement.

## Scope

- inspect the generated `ulogd.conf` and the actual plugin `.so` files shipped
  in the current `pkgs.ulogd`
- identify exactly which requested plugins are missing or renamed
- fix the router-side configuration so it only references plugins that exist in
  the packaged build
- preserve the intended NFLOG-based flow logging behavior if that remains
  practical
- keep the fix narrow; do not redesign all router observability in the same PR

## Non-Goals

- adding a larger metrics/logging stack
- changing unrelated firewall behavior
- introducing optional logging backends unless they are needed to restore the
  current feature set

## Validation

- `nix build .#nixosConfigurations.router.config.system.build.toplevel`
- `nix build .#nixosConfigurations.router-backup.config.system.build.toplevel`
- after switch, `systemctl status ulogd --no-pager` shows `active (running)` on
  router
- router rebuild no longer returns exit code `4` because of `ulogd.service`

## Notes

Treat this as a derivative repair of the broader observability work, not a new
greenfield design. The immediate task is to align config with packaged reality.
