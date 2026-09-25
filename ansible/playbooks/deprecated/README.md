# Deprecated Ansible Playbooks

This directory contains historical Ansible playbooks that have been retired as infrastructure has moved from Proxmox virtual machines to baremetal NixOS systems and declarative dendritic aspects.

---

## Deprecated Playbooks Summary

| Playbook | Original Purpose | Deprecation Reason & Modern Replacement |
|---|---|---|
| `bootstrap-nixos-router.yml` | Bootstrap router from NixOS live ISO into a Proxmox VM with dual SCSI disks (`scsi0`, `scsi1`). | **Deprecated**: Router runs on baremetal hardware (Minisforum/Protectli) via the `router-router` dendritic aspect (`den/aspects/router-router.nix`) and physical Disko partitioning (`hosts/nixos/router/disko.nix`).<br>**Replacement**: First-time install via `just install router <target-ip>`; Day-2 updates via `nixos-rebuild switch --flake .#router` or Ansible `rebuild-all.yml --limit router`. |
| `create-nixos-vm-with-igpu.yml` | Create Proxmox VM with Intel HD Graphics 530 iGPU passthrough on `pve-z170`. | **Deprecated**: Graphical workstations (`phoenix`, `emerald`) and router run directly on baremetal hardware. Proxmox desktop VMs with PCI passthrough are no longer used.<br>**Replacement**: Baremetal desktop aspects (`workstation-desktop`, `workstation-niri`, `desktop-noctalia`). |
| `bootstrap-nixos-inference.yml` | Bootstrap Proxmox QEMU SCSI VMs (`inference1..3`) with GPU passthrough using `nixos-anywhere`. | **Deprecated**: Inference has shifted from Proxmox VMs to aspect-driven deployment (`den/aspects/inference-ollama.nix`) running on baremetal `emerald` with Tesla/Nvidia acceleration. The `inference1..3` VMs are no longer active flake outputs.<br>**Replacement**: Use the `inference` / `inference-ollama` aspect on baremetal nodes. |

---

## Historical Notes

- See `docs/router-nixos-anywhere-lessons.md` for historical lessons learned from the original Proxmox VM router bootstrap.
- See `docs/host-migration-work-items/02-attic-cache-to-emerald-migration.md` for details on the migration from Proxmox LXC/VM services to baremetal `emerald`.
- Active day-to-day rebuilds and secret management are handled in `ansible/playbooks/` (`rebuild-all.yml`, `rebuild-cache-first.yml`, `update-proxmox.yml`, `setup-secrets.yml`, `configure-proxmox-zfs.yml`).
