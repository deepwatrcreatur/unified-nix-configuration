# 37 — Router-Backup DHCP Regression Lab

Status: `ready`
Suggested branch: `feat/router-backup-dhcp-regression-lab`
Priority: `high`

## Goal

Turn `router-backup` into the explicit reproduction target for the recent DHCP
and AP-adjacent regressions so future debugging does not depend on probing the
live household router.

## Why This Matters

We now have at least three distinct failure modes that need a safer test bed:

- HA partner degradation causing the primary to stop or delay local DHCP
  serving
- Kea lease-file ownership/state-directory startup failure after rollback or
  rebuild
- AP partial recovery where leases exist but devices stay absent at L2

Without a backup-focused lab path, agents will keep rediscovering these issues
against the live router.

## Tasks

- write a concise backup-only test procedure for reproducing and checking:
  - Kea start/restart behavior
  - HA timeout / `PARTNER-DOWN` transition behavior
  - lease issuance after degraded peer conditions
  - AP validation commands that distinguish DHCP success from L2 absence
- note which commands are safe on `router-backup` and which remain
  human-gated/live-router only
- capture the expected evidence bundle for future incident notes
- link the procedure from the router post-cutover and postmortem items

## Constraints

- all experimentation for this item must be performed on `router-backup`
  or against offline eval/build outputs
- do not require household traffic to fail over
- do not encode assumptions that `router-backup` hardware is healthy; the
  procedure should explicitly account for carrier faults

## Validation

- a future operator or agent can follow the documented procedure on
  `router-backup` and determine which regression layer they are seeing
- the procedure avoids any required live testing on `router`
