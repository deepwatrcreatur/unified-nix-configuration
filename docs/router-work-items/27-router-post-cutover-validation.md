# Router Post-Cutover Validation

Status: `done`
Suggested branch: `ops/router-post-cutover-validation`
Priority: `medium`

## Implementation Notes

- Added missing DHCP reservations for critical infrastructure:
  - `attic-cache` (MAC BC:24:11:CE:9D:D6)
  - `homeserver` (MAC BC:24:11:A9:BB:ED)
  - Access Points (Ruqayya, Nosheen Living, Nosheen Bedroom)
- Fixed `hosts/nixos/router/networking.nix` by removing unsupported `scopes` option.
- Created `scripts/validate-router-cutover.sh` for automated post-cutover health checks.
- Verified reservation synchronization on the live router.

## Goal

Capture and validate the concrete recovery checks that should be run after a
 router cutover or DHCP repair, with special attention to services that depend
on reserved leases.

## Why This Matters

The recent router swap left several second-order failures that were easy to
miss while focusing on basic Internet access:

- `attic-cache` was unreachable by name/IP expectations because it took a
  dynamic lease instead of its reserved address
- remote build flows implicitly depended on that address being correct
- dashboard/cutover validation did not make these dependent failures obvious

The router needs a lightweight post-cutover validation path that catches these
problems quickly.

## Tasks

- define a short post-cutover checklist for:
  - DHCP scope health
  - reserved-lease convergence
  - critical static-lease-dependent services such as `attic-cache`
  - dashboard reachability on the management plane
- add or refine one repeatable validation command/script path where useful
- document which checks are blocking for “router is healthy enough” and which
  are advisory
- note any follow-up work that should become its own queue item instead of
  being bundled here

## Constraints

- keep this focused on post-cutover operational validation, not a full router
  test harness
- do not redesign the entire management-plane smoke validation model
- keep any automation lightweight and operator-friendly

## Validation

- a human or agent can run the documented checks after a router switch and
  quickly identify whether reserved-lease-dependent services have recovered
- the check path explicitly catches the `attic-cache` wrong-IP scenario

## Deliverable

- branch commit(s)
- concise docs and/or helper scripts for post-cutover validation
