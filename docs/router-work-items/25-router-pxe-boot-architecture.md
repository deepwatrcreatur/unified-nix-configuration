# Router PXE Boot Architecture

Status: `ready`
Priority: `medium`
Branch: `docs/router-pxe-boot-architecture`

## Goal

Define the target architecture for PXE/netboot support driven from Nix, with a
clear answer for which pieces belong in this repo versus
`nix-router-optimized`.

## Why

There is currently no first-class work item or documented design for PXE boot
support in the router stack, even though the homelab needs a path for
network-based boot/install workflows.

Before implementation, the repo needs an explicit design for:

- DHCP `next-server` / bootfile responsibilities
- TFTP or HTTP delivery expectations
- BIOS versus UEFI client support expectations
- how this should compose with the existing router role and future DHCP work

## Scope

- inspect current router DHCP/DNS/module structure and note likely attachment
  points for PXE support
- decide whether the primary configuration surface should live in
  `nix-router-optimized`, this repo, or a split model
- document a minimal operator-facing model for enabling PXE per network or VLAN
- identify the dependencies that would likely be required:
  - DHCP option support
  - boot artifact serving
  - firewall allowances
  - optional menu or ISO delivery layers
- leave a concrete recommendation for the first implementation PR

## Non-Goals

- fully implementing PXE in this PR
- selecting a final boot-menu product for every use case
- redesigning the whole DHCP architecture at the same time

## Validation

- the design makes module ownership and layering explicit
- a follow-up agent can implement the first slice without reopening the basic
  architecture question
- the design explicitly notes open questions around BIOS/UEFI and artifact
  serving

## Notes

Treat this as the design gate for future PXE work. The output should be
practical enough that the next implementation task can stay PR-sized.
