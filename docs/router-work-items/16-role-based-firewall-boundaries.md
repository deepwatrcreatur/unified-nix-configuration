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

- [x] Inventory current firewall rules and how they relate to WAN/LAN/management roles.
- [x] Propose a role-oriented grouping (e.g., LAN_IN, WAN_LOCAL, MGMT_IN) that matches existing behavior.
- [x] Update router modules/config to make the role-to-rule-set mapping explicit without large behavior changes.
- [x] Document the new mapping for operators, including how to extend it safely.

## Validation

- Router and router-backup builds succeed.
- Effective firewall behavior matches current intent (no unexpected exposure or breakage).
- The relationship between interface roles and rule sets is obvious from config and docs.

## Outcome Notes

- `nix-router-optimized` has been refactored to use role-based chains (`WAN_LOCAL`, `LAN_LOCAL`, `MGMT_LOCAL`, `WAN_IN`, `LAN_IN`, `MGMT_IN`) internally.
- New role-specific extension options (`extraWanLocalRules`, `extraLanLocalRules`, etc.) have been added to the `router-firewall` module.
- `hosts/nixos/router/role.nix` now uses `extraLanLocalRules` for iperf3, making the role-to-rule mapping explicit.
- `docs/router-firewall-roles.md` provides comprehensive documentation on the new role-based firewall structure.

