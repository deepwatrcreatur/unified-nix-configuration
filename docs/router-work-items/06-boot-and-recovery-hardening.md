# Boot And Recovery Hardening

Status: `in-progress`
Suggested branch: `refactor/router-boot-recovery`
Priority: `medium-high`

## Goal

Keep recovery paths permanently available for the Proxmox-hosted router.

## Required Recovery Paths

- management SSH
- Proxmox serial console
- qemu guest agent

## Current Situation

Recent work already added/fixed:

- serial console settings on the VM side
- serial kernel param in router config
- qemu guest agent enabled in router role

This work item is about hardening and documenting that, not re-discovering it.

## Tasks

- Verify `router` and `router-backup` both include guest-agent and serial
  console behavior.
- Add a check/assertion if feasible.
- Document the Proxmox recovery procedure:
  - management SSH path
  - `qm terminal`
  - expected VM config
- Document the known standby/dev topology clearly.

## Validation

- eval/build for router and router-backup
- doc walkthrough is accurate against actual Proxmox config

## Do Not

- do not mix with storage migration or reinstall automation unless needed
