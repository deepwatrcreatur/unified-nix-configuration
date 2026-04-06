# Role-Based Firewall Boundaries

Status: `done`
Suggested branch: `feat/router-role-based-firewall-boundaries`
Priority: `medium`
Blocked By: `07-observability-and-flow-logging.md`
Unblocks: future router firewall/module-boundary cleanup

## Goal

Tighten the mapping between interface roles (WAN, LAN, management) and firewall rule sets so the intent is as clear as VyOS-style zones while keeping the current nftables-based implementation.

## Why This Matters

Clear role-to-policy mapping makes it easier to reason about router behavior, reduces accidental policy drift, and sets up future work on observability and policy routing without changing core invariants.

## Tasks

- Inventory current firewall rules and how they relate to WAN/LAN/management roles.
- Propose a role-oriented grouping (e.g., LAN_IN, WAN_LOCAL, MGMT_IN) that matches existing behavior.
- Update router modules/config to make the role-to-rule-set mapping explicit without large behavior changes.
- Document the new mapping for operators, including how to extend it safely.

## Validation

- Router and router-backup builds succeed.
- Effective firewall behavior matches current intent (no unexpected exposure or breakage).
- The relationship between interface roles and rule sets is obvious from config and docs.

## Outcome Notes

- `services.router-optimizations.interfaces` already models WAN / LAN /
  management roles and devices for the router.
- `services.router-firewall` automatically derives interface lists from those
  roles when explicit lists are not set, so the firewall is already
  role-aware.
- `docs/router-firewall-roles.md` explains how these pieces fit together and
  how to extend the router firewall safely.
