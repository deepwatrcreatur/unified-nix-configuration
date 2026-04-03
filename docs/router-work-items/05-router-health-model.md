# Router Health Model

Status: `done`
Suggested branch: `feat/router-health-model`
Priority: `high`

## Goal

Represent router health explicitly instead of inferring it indirectly from
systemd unit noise.

## Desired States

- healthy
- degraded: management missing
- degraded: LAN address missing
- degraded: WAN link/address missing
- degraded: monitoring unavailable

## Why This Matters

The dashboard previously showed a pile of service failures, but the real issue
was “LAN address missing.” Operators should see the failure domain directly.

## Tasks

- Add explicit health checks for:
  - management IP present
  - production LAN IP present
  - WAN carrier / WAN address state
- Surface these in the router dashboard.
- Distinguish service failure from interface-state failure.
- Consider whether this belongs in the upstream router dashboard module.

## Validation

- dashboard shows interface-level health, not just unit-level status
- no ambiguity about whether the router is recoverable but degraded

## Outcome

- Added explicit health services (`health-mgmt-ip`, `health-lan-ip`, `health-wan-carrier`, `health-wan-ip`) in `hosts/nixos/router/role.nix`.
- Surfaced these services in `services.router-dashboard.services` so health appears directly in the dashboard.
- Builds succeed for both `router` and `router-backup` with the new health model.

## Do Not

- do not collapse all failures into one red/green bit
