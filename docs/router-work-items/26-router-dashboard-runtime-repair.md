# Router Dashboard Runtime Repair

Status: `done`
Suggested branch: `fix/router-dashboard-runtime-repair`
Priority: `high`

## Goal

Repair the remaining router-dashboard runtime regressions exposed during the
router swap and turn them into a narrow, reviewable fix stream.

## Why This Matters

The dashboard is intended to shorten incident response time, but several cards
regressed in ways that obscured the real system state:

- LAN/WAN/management IP cards were blank due to interface-key mismatches
- the Caddy card could not validate Cloudflare state because the dashboard
  could not read the token
- the fail2ban card attempted a sudo path that was incompatible with the
  service sandbox/capability model

These are implementation bugs, not a redesign of the dashboard architecture.

## Tasks

- verify the interface-card data path end-to-end between:
  - `services.router-dashboard.interfaces`
  - dashboard backend `/api/interfaces/stats`
  - frontend widget lookup keys
- fix the fail2ban status path so the card works under the hardened
  `router-dashboard` service model
- ensure the dashboard can read only the specific secret material needed for
  Caddy diagnostics without broadening secret exposure carelessly
- confirm the Caddy card reports live health rather than a false token error
- keep the patch narrow and avoid bundling unrelated dashboard redesign work

## Constraints

- split upstream-vs-host-local changes cleanly if both repos are touched
- prefer obvious bug-fix scope suitable for direct merge unless review uncovers
  deeper structural concerns
- do not mix Technitium DHCP sync logic into this branch

## Validation

- dashboard cards for LAN, WAN, and management show the correct IPv4 addresses
- fail2ban card reports real jail status instead of sudo capability errors
- Caddy card reports Cloudflare token availability and live DNS comparison
  accurately

## Deliverable

- one focused branch/PR-sized change stream
- short verification notes from the live router after switch
