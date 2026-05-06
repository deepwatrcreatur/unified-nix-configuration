# 43 — Optional Extra Routed Networks

Status: `done`
Suggested branch: `feat/router-optional-extra-networks`
Priority: `medium`

## Goal

Finish productizing extra routed VLAN-backed networks such as `iot` and
`guest` so flake users can enable them explicitly instead of inheriting them as
hard-coded router-role behavior.

## Why This Matters

The incident recovery branch already moved in the right direction:

- `router` explicitly opts into `iot` and `guest`
- `router-backup` now defaults to only `lan` + `management`

That proves the feature should exist, but as a general router-flake capability
rather than a host-specific assumption.

## Tasks

- replace boolean feature flags with a cleaner reusable option surface if
  needed
- make extra networks configurable by flake users:
  - name
  - VLAN ID
  - subnet/gateway
  - policy-routing behavior
  - DHCP binding participation
  - UPnP listening behavior
- preserve the current `router` behavior as an explicit opt-in configuration
- document migration expectations for hosts currently assuming fixed `iot` and
  `guest` names

## Constraints

- do not widen this into a full router-topology redesign
- do not break the current recovered `router` configuration
- validate first on `router-backup`

## Validation

- base router role with no extra networks => only main LAN is routed/served
- host opt-in => additional VLAN-backed routed networks render correctly
- Kea and UPnP bindings track the enabled networks only

## Outcome

- the shared router role now exposes `enableIotNetwork` and
  `enableGuestNetwork` feature flags instead of assuming those networks for
  every host
- `router` opts into the existing `iot` and `guest` behavior explicitly, so
  the recovered family network behavior did not change
- `router-backup` leaves those networks disabled by default, making the lab
  target simpler and safer while preserving the feature for flake users
