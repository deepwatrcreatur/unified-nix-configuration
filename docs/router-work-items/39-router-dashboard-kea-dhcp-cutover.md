# 39 — Router Dashboard Kea DHCP Cutover

Status: `ready`
Suggested branch: `feat/router-dashboard-kea-dhcp-cutover`
Priority: `high`

## Goal

Finish the dashboard DHCP observability cutover so the DHCP widget reflects the
actual Kea-based DHCP system instead of calling Technitium's DHCP API.

## Why This Matters

During the 2026-05-05 incident:

- `kea-dhcp4-server` was `active`
- Kea was issuing fresh leases again
- but `/api/dhcp/leases` returned `Technitium DNS not configured or unavailable`
- the DHCP widget therefore showed `OFFLINE`

That is now misleading by design: DHCP has moved to Kea, but the widget still
assumes Technitium is the provider.

## Tasks

- implement or complete the provider-agnostic DHCP status snapshot path from
  [`28-dhcp-provider-pluggable-observability.md`](./28-dhcp-provider-pluggable-observability.md)
- add a Kea-backed poller or reader that can expose:
  - provider name
  - leases
  - scope/subnet summary
  - last updated time
- update the dashboard DHCP widget/API to consume the normalized snapshot
  instead of Technitium's DHCP endpoints
- preserve a clean "data unavailable" state if the snapshot is missing

## Constraints

- keep this scoped to dashboard/observability behavior, not a broad DHCP
  module redesign
- do not depend on the live `router` for iterative testing; validate on
  `router-backup` or offline fixtures first

## Validation

- with Kea active, `/api/dhcp/leases` returns `available: true`
- the DHCP widget shows real lease counts from Kea-backed data
- removing Technitium DHCP assumptions no longer breaks the widget
