# Stable Interface Matching

Status: `ready`
Suggested branch: `refactor/router-stable-interface-matching`
Priority: `very high`

## Goal

Stop depending on fragile interface names like `enp6s16` and `enp6s17` for the
production router role.

## Why This Matters

The router outage was narrowed to interface assumptions and carrier state.
Recoverability improved once management stayed up, but the design still relies
on kernel naming stability.

For a Proxmox VM with passthrough NICs, the important identities are:

- LAN physical/passthrough NIC
- WAN physical/passthrough NIC
- management virtio NIC

These should be matched by stable properties where possible.

## Current Relevant Files

- [`hosts/nixos/router/configuration.nix`](../../hosts/nixos/router/configuration.nix)
- [`hosts/nixos/router/networking.nix`](../../hosts/nixos/router/networking.nix)
- [`hosts/nixos/router-backup/configuration.nix`](../../hosts/nixos/router-backup/configuration.nix)
- upstream router-networking modules from `nix-router-optimized`

## Inputs Known From Live System

Current router VM observations from live inspection:

- `ens16`
  - path `pci-0000:06:10.0`
  - driver `igc`
  - MAC `02:76:c6:01:2a:af`
- `ens17`
  - path `pci-0000:06:11.0`
  - driver `igc`
  - MAC `02:76:c6:01:2a:b0`
- `ens18`
  - management virtio NIC

These values are useful only if they are still stable after reboot or rebuild.

## Tasks

- Inspect what `nix-router-optimized` already supports for stable interface
  matching.
- Prefer one of:
  - MAC-based matching
  - PCI path-based matching
  - systemd `.link` / `.network` match config
- Make management NIC matching explicit too if practical.
- Document the expected mapping for:
  - router
  - router-backup
  - Proxmox VM config

## Validation

- local eval/builds for `router` and `router-backup`
- confirm generated networkd config no longer relies on kernel name alone

## Do Not

- do not mix this with VLAN work
- do not change the shared production router identity model
