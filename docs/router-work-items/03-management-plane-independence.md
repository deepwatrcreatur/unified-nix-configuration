# Management Plane Independence

Status: `in-progress`
Suggested branch: `feat/router-management-plane-independence`
Priority: `very high`

## Goal

Make management reachability a first-class invariant, independent of LAN/WAN
 state.

## Why This Matters

The router was recoverable because `192.168.100.100` remained available even
when the production LAN role was broken. That needs to be treated as an
intentional design, not an accident.

## Desired Behavior

- `router` management stays reachable at `192.168.100.100`
- `router-backup` management stays reachable at `192.168.100.99`
- SSH, dashboard, and key diagnostics continue to work from management even if:
  - WAN is absent
  - LAN has no carrier
  - routing/NAT is degraded

## Current Relevant Files

- [`hosts/nixos/router/configuration.nix`](../../hosts/nixos/router/configuration.nix)
- [`hosts/nixos/router/role.nix`](../../hosts/nixos/router/role.nix)
- [`hosts/nixos/router-backup/configuration.nix`](../../hosts/nixos/router-backup/configuration.nix)
- [`modules/nixos/router/common.nix`](../../modules/nixos/router/common.nix)
- [`lib/hosts.nix`](../../lib/hosts.nix)

## Tasks

- Audit router-local services that still conceptually assume LAN-first instead
  of management-first recovery.
- Ensure dashboard/API binds and links remain usable on management.
- Ensure management IPs derive from inventory only, not repeated literals.
- Add an explicit statement in docs that management is the supported recovery
  plane.

## Validation

- eval/build of router and router-backup
- manual management reachability after switch
- dashboard links render correctly for management and LAN

## Do Not

- do not make management and LAN identities share one IP
- do not require WAN for any management-plane feature
