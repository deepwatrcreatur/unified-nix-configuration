# Router Health Model

Status: `in-progress`
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

## Do Not

- do not collapse all failures into one red/green bit
