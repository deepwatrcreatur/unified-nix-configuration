# Router miniupnpd Interface Repair

Status: `ready`
Priority: `high`
Branch: `fix/router-miniupnpd-interface-repair`

## Goal

Fix the router's `miniupnpd` configuration so it binds to the correct LAN
interface names instead of an invalid IPv4 CIDR string and starts cleanly after
activation.

## Why

During the 2026-04-21 router activation, `miniupnpd.service` failed with:

- `please specify LAN network interface by name instead of IPv4 address : 10.10.10.1/16`
- `can't parse "10.10.10.1/16" as a valid interface name`

This is a concrete config-generation bug in the router path, not an operator
error on the host.

## Scope

- trace where the `miniupnpd` config derives its LAN-side binding value
- change the config generation so LAN bindings use interface names
- preserve the intended WAN/LAN exposure model and existing router topology
- verify the generated config and service start successfully on the live router

## Non-Goals

- changing the overall UPnP policy or firewall posture
- reworking unrelated router networking abstractions
- bundling additional miniupnpd features

## Validation

- generated `miniupnpd.conf` uses valid interface names for LAN bindings
- `systemctl status miniupnpd.service` reports `active`
- router rebuild/test no longer reports `miniupnpd.service` as failed

## Notes

Observed on live `router` during activation of merged commit `3af2d70c` on
2026-04-21.
