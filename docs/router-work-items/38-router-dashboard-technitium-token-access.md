# 38 — Router Dashboard Technitium Token Access

Status: `ready`
Suggested branch: `fix/router-dashboard-technitium-token-access`
Priority: `high`

## Goal

Make the router dashboard's DNS widget reflect the real Technitium state after
rollback/rebuild events instead of showing `OFFLINE` purely because the
dashboard cannot read the API token.

## Why This Matters

During the 2026-05-05 incident:

- `technitium-dns-server` was `active`
- the dashboard service status API reported it as `active`
- but `/api/dns/stats` returned `Technitium DNS not configured or unavailable`

The current likely cause is permission mismatch:

- dashboard user: `router-dashboard`
- token file: `/var/lib/technitium-dns-server/nix-router-api-token`
- file mode on the live router: `0400 root:root`

That makes the widget say "offline" even though DNS itself is healthy.

## Tasks

- trace how the Technitium API token is provisioned to the dashboard
- change the runtime path/permissions so `router-dashboard` can read exactly
  the required token material and nothing broader
- keep the fix narrow to the DNS/API-token path
- add a clear failure message if the token path is missing or unreadable

## Constraints

- do not reintroduce broad secret exposure to the dashboard user
- do not couple this item to the DHCP provider redesign
- validation and deployment for this item should be done on `router-backup`
  first

## Validation

- `technitium-dns-server` active + readable token => `/api/dns/stats` returns
  `available: true`
- missing/unreadable token => API returns an actionable message, not a generic
  "offline"
