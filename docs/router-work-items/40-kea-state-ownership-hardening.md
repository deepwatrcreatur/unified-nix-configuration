# 40 — Kea State Ownership Hardening

Status: `ready`
Suggested branch: `fix/kea-state-ownership-hardening`
Priority: `high`

## Goal

Ensure `kea-dhcp4-server` reliably starts after rebuilds and rollbacks by
hardening ownership and lifecycle handling for its state directory and lease
files.

## Why This Matters

On 2026-05-05, after booting an earlier router generation:

- `kea-dhcp4-server` was not serving DHCP at all
- the immediate cause was not HA state but startup failure
- `/var/lib/private/kea`, `dhcp4.leases`, and `dhcp4.leases.2` were not
  usable by the `kea` service user
- a manual ownership repair and restart restored DHCP

That means a rollback can currently turn a recoverable HA problem into a full
DHCP outage.

## Tasks

- inspect how the Kea state directory and lease files are declared in NixOS
  for this router role
- make ownership/permissions deterministic across rebuilds and boot
- prefer a declarative/systemd-managed fix over an ad hoc manual repair
- document how this interacts with `DynamicUser`, `StateDirectory`, and any
  custom lease-file paths

## Constraints

- do not rely on live `router` experimentation for this item
- validate on `router-backup` first or with offline inspection/build outputs
- keep the fix narrow to state-directory/lease-file startup correctness

## Validation

- after boot or restart, `kea-dhcp4-server` starts without manual `chown`
- lease files are created or reopened with the expected owner/mode
- the configuration remains compatible with the existing HA design work
