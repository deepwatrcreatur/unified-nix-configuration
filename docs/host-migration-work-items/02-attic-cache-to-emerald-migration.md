# 02 Attic Cache To Emerald Migration

Status: `in-progress`
Suggested branch: `feat/emerald-cache-migration`
Priority: `high`
Depends on: `01-decouple-hostname-role-checks`

## Goal

Migrate the Nix binary cache from functional hostname `attic-cache` to node identity `emerald` as a baremetal NixOS host with Disko partitioning and UEFI systemd-boot, establishing `attic-cache`, `cache`, and `nix-cache` as DNS and SSH aliases.

## Scope

1. In `lib/hosts.nix`:
   - Rename host entry `attic-cache` to `emerald` at `ip = "10.10.11.55"`.
   - Set physical MAC reservation `90:e2:ba:7f:e0:3c`.
   - Add `aliases = [ "tomahawk" "attic-cache" "cache" "nix-cache" ];`.
   - Decommission `pve-tomahawk`.
2. In `den/inventory/hosts.nix`:
   - Rename host `attic-cache` to `emerald`.
   - Update `name = "emerald";` and `hostPath = ../hosts/emerald;`.
3. In `den/hosts/` and `hosts/nixos/emerald/`:
   - Move `den/hosts/attic-cache/` to `den/hosts/emerald/`.
   - Update `name = "emerald"` in `den/hosts/emerald/default.nix`.
   - Transition from LXC to baremetal: remove `lxc-container.nix` and `lxc-systemd-suppressions.nix`.
   - Add `hosts/nixos/emerald/disko.nix` targeting the 4TB Netac NVMe SSD (`nvme-Netac_NVMe_SSD_4TB_RN202310074T843759`).
   - Add `hosts/nixos/emerald/hardware-configuration.nix` with Ryzen 9 7950X3D hardware modules and ZFS/XFS filesystem support.
   - Enable `systemd-boot` and UEFI bootloader.
4. In `users/`:
   - Move `users/deepwatrcreatur/hosts/attic-cache` -> `users/deepwatrcreatur/hosts/emerald`.
   - Move `users/root/hosts/attic-cache` -> `users/root/hosts/emerald`.
5. In Agenix & Secrets:
   - Generate dedicated machine identity for `emerald` (`ssh-keys/agenix-machine-identities/emerald.pub`).
   - Remove `pve-tomahawk` from `secrets.nix` and `lib/remote-builder.nix`.
   - Run `just rekey`.
6. Validate and open PR.

## Validation

- `nix build .#checks.x86_64-linux.inventory-consistency --no-link`
- `nix eval .#nixosConfigurations.emerald.config.system.build.toplevel.drvPath --raw`
- DNS zone checks confirm `attic-cache` CNAME points to `emerald`.
