# Technitium DHCP Sync Hardening

Status: `done`
Suggested branch: `fix/router-technitium-dhcp-sync-hardening`
Priority: `high`

## Implementation Notes

- Deduplicated shell helpers (`technitium_request`, `resolve_scope_name`) into a shared snippet.
- Hardened `ntpSyncScript` to use the same error-checking logic as scope/reservation sync.
- MAC address matching now uses normalized format (uppercase, no separators) for reliable existing-reservation detection.
- Reservation sync is now explicitly idempotent and supports updates (remove then re-add if mismatched).
- Added detailed comments explaining the convergence model.
- Pushed hardening branch to `nix-router-optimized`.

## Goal

Harden the `router-technitium` DHCP sync path in `nix-router-optimized` so it
converges deterministically and fails loudly instead of reporting false
success.

## Why This Matters

The current router incident showed that the existing Technitium integration was
too optimistic:

- scope sync could report success even when the live Technitium state did not
  match the declarative state
- reservation sync could miss existing reservations because of MAC-format
  mismatches
- reservation replacement behavior was not robust enough to recover from stale
  live state

This is structural module work and should land as an upstream-quality PR in
`nix-router-optimized`, not as an ad hoc host-local workaround.

## Tasks

- review the current `modules/router-technitium.nix` sync scripts end-to-end
- make API success/failure handling explicit for scope sync and reservation
  sync
- make legacy scope handling deterministic:
  - desired scope exists
  - legacy scope exists
  - neither exists
- normalize reservation identity matching so Technitium MAC formatting does not
  cause duplicate/conflicting reservations
- make reservation update/replace behavior explicit and idempotent
- add comments/tests/docs sufficient for future agents to understand the
  convergence model

## Constraints

- treat this as `nix-router-optimized` module work
- optimize for a clean PR with bot-reviewable scope
- do not mix unrelated dashboard or host-local router fixes into the same PR
- preserve Technitium as the current DHCP engine for now; this is not the Kea
  migration task

## Validation

- declarative scope sync converges from a live `Default` scope to the desired
  `LAN` scope on a real router
- declarative reservations appear in the live Technitium scope after switch
- rerunning the sync services is idempotent
- sync units fail with actionable errors when Technitium rejects an API call

## Deliverable

- a PR against `nix-router-optimized`
- concise outcome notes describing the live-state transitions that were tested
