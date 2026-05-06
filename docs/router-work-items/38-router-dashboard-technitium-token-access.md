# 38 — Router Dashboard Technitium Token Access

Status: `ready`
Suggested branch: `fix/router-dashboard-technitium-token-access`
Priority: `high`

## Goal

Make the router dashboard's DNS widget reflect the real Technitium state after
rollback/rebuild events instead of showing `OFFLINE` because the API endpoint
is unavailable or the dashboard lacks the narrow token access it needs.

## Why This Matters

During the 2026-05-05 incident and follow-up validation:

- `technitium-dns-server` was `active`
- the dashboard service status API reported it as `active`
- but `/api/dns/stats` returned `Technitium DNS not configured or unavailable`

- on the recovered live `router`, DNS stats later worked again once the runtime
  path was corrected
- on `router-backup`, the same widget still reports unavailable because
  Technitium itself is not running there

So the remaining work is not "make the secret world-readable." It is to make
the dashboard's DNS behavior explicit and accurate across both host profiles.

## Tasks

- trace how the Technitium API token is provisioned to the dashboard on hosts
  where Technitium is enabled
- keep the dashboard on a narrow token path that exposes only the required API
  token material
- make the DNS widget return an actionable message that distinguishes:
  - Technitium not enabled on this host
  - token path missing/unreadable
  - local Technitium API refusing connections
- keep the fix narrow to the DNS/API-token path rather than coupling it to the
  DHCP widget redesign

## Constraints

- do not reintroduce broad secret exposure to the dashboard user
- do not couple this item to the DHCP provider redesign
- validation and deployment for this item should be done on `router-backup`
  first

## Validation

- Technitium enabled + reachable + readable token => `/api/dns/stats` returns
  `available: true`
- Technitium intentionally absent on a host such as `router-backup` => API
  returns an explicit "not enabled on this host" style message
- missing/unreadable token => API returns an actionable message, not a generic
  "offline"
