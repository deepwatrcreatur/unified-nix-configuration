# 44 — Kea Stork Dashboard

Status: `ready`
Suggested branch: `feat/router-kea-stork`
Priority: `medium`

## Goal

Add optional ISC Stork support so flake users can get first-class Kea
observability and a real DHCP/IPAM-oriented dashboard rather than relying only
on the generic router dashboard.

## Why This Matters

Kea is now a real part of the router stack, but its observability story is
still indirect:

- router dashboard still needs Kea-specific cutover work
- DHCP incidents required direct journal and lease-file inspection
- there is no dedicated Kea/Stork UI today

Stork is the obvious missing companion if we want the flake to serve users who
run Kea seriously.

## Tasks

- evaluate whether Stork is available in nixpkgs or needs packaging/wrapping
- design an optional module surface for Stork:
  - server
  - agent
  - credentials/secrets
  - listen address / reverse-proxy integration
- decide whether Stork belongs on:
  - the main router
  - `router-backup`
  - or a separate observability host by default
- integrate the resulting service with the router dashboard links or homelab
  surface where appropriate
- document resource/operational tradeoffs

## Constraints

- optional only; do not make Stork a base-router dependency
- do not couple this item to the immediate dashboard token fix
- validate on `router-backup` first unless the architecture clearly argues for
  a separate host

## Validation

- disabled by default => existing router behavior unchanged
- enabled => Kea/Stork services start cleanly and expose a usable web UI
- DHCP lease/state visibility is available without hand-parsing journals

