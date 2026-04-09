# Router PXE Boot Module Plumbing

Status: `in-progress`
Priority: `medium`
Branch: `feat/router-pxe-boot-config`

## Goal

Add a first implementation slice for PXE boot configuration in
`nix-router-optimized` or the nearest suitable repo-owned module boundary.

## Why

Once the architecture is clear, the router stack needs a real configuration
surface for PXE so agents and operators are not forced into ad hoc DHCP/TFTP
edits outside Nix.

The desired outcome is not just "PXE exists somewhere", but "PXE can be
configured intentionally from the router model".

## Scope

- implement the first approved configuration surface from
  [`25-router-pxe-boot-architecture.md`](./25-router-pxe-boot-architecture.md)
- support the minimum viable boot parameters needed for at least one real
  netboot path
- keep the implementation modular so it can stay disabled by default
- include any required firewall/service wiring for the chosen delivery path
- document how a host or VLAN would opt into the feature

## Non-Goals

- solving every PXE workflow in one PR
- bundling iVentoy unless the evaluation explicitly recommends it as the first
  target
- large DHCP architecture rewrites unrelated to the initial PXE path

## Inputs

- architecture decision from
  [`25-router-pxe-boot-architecture.md`](./25-router-pxe-boot-architecture.md)
- iVentoy recommendation from
  [`26-router-iventoy-evaluation.md`](./26-router-iventoy-evaluation.md)

## Validation

- the new PXE configuration evaluates cleanly
- the feature is disabled by default
- docs show one concrete example of enabling the supported boot path

## Notes

The architecture and iVentoy evaluation are now recorded, so implementation can
proceed as a narrow first slice.
