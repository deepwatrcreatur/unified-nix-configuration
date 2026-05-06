# 34 — AP Recovery Postmortem Gap

Status: `ready`
Suggested branch: `docs/ap-recovery-postmortem-gap`
Priority: `medium`

## Goal

Close the documentation gap around partial AP recovery after router / DHCP / HA
experimentation.

## Why This Matters

At least one incident pattern has now repeated:

- reserved leases remained correct
- one AP recovered normally
- other APs stayed absent at L2 until manual intervention

That is operationally important because it looks like "DHCP is fixed but Wi-Fi
is still broken," and the recovery path is different from lease repair.

## Tasks

- turn the raw AP regression note into a concise post-mortem
- record the decision tree for:
  - lease exists
  - ARP fails
  - one AP returns while others do not
  - manual power cycle required
- document switch / PoE limitations explicitly
- link the post-mortem from router cutover and AP-related docs

## Current Artifact

- incident report now exists at:
  [`../router-dhcp-ha-ap-incident-2026-05-05.md`](../router-dhcp-ha-ap-incident-2026-05-05.md)

## Constraints

- keep this operational, not architectural
- do not assume managed PoE or controller access exists
- do not require experiments on the live `router`; any validation commands
  added here should be safe to run from `router-backup` or from a management
  host

## Validation

- a future operator can determine within minutes whether the problem is still
  router-side or has moved to AP/device recovery
- the repeated AP failure pattern is discoverable in repo history
