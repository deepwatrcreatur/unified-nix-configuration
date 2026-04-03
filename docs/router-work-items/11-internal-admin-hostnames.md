# Internal Router Admin Hostnames

Status: `ready`
Suggested branch: `feat/router-internal-admin-hostnames`
Priority: `medium`

## Goal

Expose internal-only admin hostnames for router services such as:

- `technitium.deepwatercreature.com`
- `kea.deepwatercreature.com`

for browsing from the homelab, without turning them into public ingress.

## Why This Matters

Friendly internal names improve operator UX and make it easier to grow a
multi-service router stack without relying on raw IPs and ports.

## Tasks

- define how internal-only hostnames should be represented in inventory
- decide whether these belong in `publicIngressServices` or a separate
  internal/admin hostname list
- route them through Caddy or another local reverse-proxy path
- ensure they resolve only inside the homelab / management paths

## Constraints

- these are not public DDNS names
- do not publish them to Cloudflare/public ingress by default
- preserve management-plane recovery access by raw IP even if Caddy is broken

## Deliverable

- implementation if feasible, or
- a concrete plan with the required inventory and Caddy changes

## Validation

- internal DNS resolution works
- Caddy serves the chosen internal names
- public ingress checks do not treat them as external names
