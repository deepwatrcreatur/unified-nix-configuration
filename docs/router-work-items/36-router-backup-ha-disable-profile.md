# 36 — Router-Backup HA Disable Profile

Status: `done`
Suggested branch: `feat/router-backup-ha-disable-profile`
Priority: `high`

## Goal

Create a reversible configuration path that disables the HA participation logic
on `router-backup` while preserving its value as the safe development and
validation target.

## Why This Matters

The active outage pattern is no longer theoretical:

- the passed-through NIC on `router-backup` is unreliable
- when that fault participates in HA, the primary router can degrade DHCP
  behavior or recovery timing
- the household depends on `router` staying online while experiments continue

We need a branch-sized change that makes `router-backup` safe to rebuild and
test without reintroducing HA-induced instability on the live router.

## Tasks

- identify the minimum config needed so `router-backup` no longer participates
  in DHCP/HA state exchange during testing
- preserve management access to `router-backup` at `192.168.100.99`
- preserve enough service behavior on `router-backup` to validate builds and
  inspect local logs
- document exactly what is disabled and how to re-enable it later
- avoid broad router role redesign in this item

## Constraints

- all deployment and validation steps for this item must target
  `router-backup`, not `router`
- do not require a cutover of household traffic
- prefer a narrow flag/profile/override rather than a permanent semantic
  rewrite of the router role

## Validation

- `nix build .#nixosConfigurations.router-backup.config.system.build.toplevel`
- if deployed, `router-backup` stays reachable on the management plane
- after deployment, `router-backup` no longer advertises or depends on live HA
  peer participation for DHCP serving experiments

## Outcome

- `router-backup` now keeps `192.168.100.99/24` as its management address
  without a manual console-side `ip addr add`
- `keepalived` is no longer present on `router-backup`
- `kea-dhcp4-server` starts cleanly again with a pre-start ownership fix for
  the lease files
- the backup host no longer imports the primary router's
  `hosts/nixos/router/networking.nix`, which was duplicating DHCP/DNS policy on
  the lab node
