# Memory Archive: akes-unified-nix-configuration / e5b24499

**Source**: `/home/deepwatrcreatur/.claude/projects/-home-deepwatrcreatur-flakes-unified-nix-configuration/e5b24499-273a-4788-ad01-92734236b20b.jsonl`  
**Date**: 2026-04-01  
**Findings**: 1

---

## Finding 1 (score=4, role=user, ts=2026-03-31T23:33:00.402Z)

This session is being continued from a previous conversation that ran out of context. The summary below covers the earlier portion of the conversation.

Summary:
1. Primary Request and Intent:
   - **router-backup flake output**: Create a second router NixOS output for emergency failover, using an Intel I219 dual-port NIC (virtio for now, passthrough on deployment), no logs disk, inheriting the router/gateway stack
   - **Intel GPU passthrough PoC**: Pass through Intel HD Graphics 530 (pve-z170) to a new VM using the graphical NixOS ISO already in tank-iso
   - **Fix VM 200 boot**: Router VM was stuck with "no bootable device" — attach minimal NixOS ISO and change boot order
   - **Install router via nixos-anywhere**: Bootstrap the router NixOS configuration onto VM 200 using just install recipe
   - **Fix CI failures**: `inventory-consistency` check fails because `router-backup` is missing from `lib/hosts.nix`
   - **Gateway host removal** (user's most recent architectural request): "the gateway host doesn't exist anymore. It's fine to delete it from repo and consolidate config in the router and router-backup outputs, with a less complex inheritance hierarchy"
   - **NIC name updates**: User observed during ISO boot that NICs are `enp1s0`, `enp2s0`, `ens18`

2. Key Technical Concepts:
   - NixOS flake outputs, den inventory framework, `mkHostModule` pattern
   - agenix secrets management and machine identities
   - nixos-anywhere for remote NixOS installation with disko
   - Limine EFI bootloader on OVMF QEMU VMs
   - `lib.mkForce` vs `lib.mkOverride` priority conflicts in NixOS module system
   - Intel iGPU PCI passthrough via vfio-pci (HD Graphics 530, 8086:1912)
   - IOMMU/VT-d, vfio-pci binding via modprobe softdep + kernel cmdline
   - Proxmox QEMU VM serial console (UNIX socket at `/var/run/qemu-server/<vmid>.serial0`)
   - btrfs subvolume layout (@ root, @home, @snapshots) with ESP partition
   - SSH agent interference causing "Too many authentication failur

---
