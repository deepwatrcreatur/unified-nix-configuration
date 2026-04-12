# Router Caddy Source Drift Repair

Status: `done`
Priority: `high`
Branch: `fix/router-caddy-source-drift`

## Goal

Repair the current router rebuild failure caused by a fixed-output hash mismatch
in the Caddy-with-plugins source path.

## Why

Router rebuilds are currently failing with a concrete fixed-output derivation
error:

- `caddy-src-with-plugins-...-2.11.2.drv` hash mismatch
- downstream `caddy`, `etc`, and `nixos-system-router` builds fail

This blocks router rebuilds during an already degraded period and should be
treated as an immediate runtime repair.

## Scope

- identify where the current Caddy plugin source derivation is defined
- determine whether the mismatch comes from upstream source drift, a stale hash,
  plugin-set churn, or an incorrect fetch path
- update the pinned hash or source-generation path so router rebuilds work again
- keep the repair narrow and document the root cause briefly

## Non-Goals

- redesigning the full reverse-proxy stack
- broad Caddy refactors unrelated to the hash mismatch
- mixing in unrelated router service fixes

## Validation

- `nix build .#nixosConfigurations.router.config.system.build.toplevel`
  progresses past the current Caddy failure
- the regenerated or pinned source hash is explained well enough that future
  agents do not "fix" it blindly again

## Notes

This is separate from the DHCP/cache problems. It is a direct rebuild blocker
and should be handled as its own PR-sized repair.
