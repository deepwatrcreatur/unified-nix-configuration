# Proxmox Ansible Moved

Proxmox host Ansible automation has moved to the `proxmox-host-configuration` repo.

Current location:

- `/home/deepwatrcreatur/flakes/proxmox-host-configuration/ansible`

That repo now owns:

- Proxmox host inventory
- Proxmox host group variables
- Proxmox bootstrap playbooks
- apt proxy rollout for Proxmox hosts

`unified-nix-configuration` remains the Nix source of truth consumed by those playbooks.
