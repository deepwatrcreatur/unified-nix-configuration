# 11 Host Metadata Source Of Truth

Status: `ready`

Suggested branch: `refactor/tooling-host-metadata-boundary`

## Goal

Clarify and, where practical, tighten the split between `den/inventory` and
`lib/hosts.nix` so host metadata is easier to reason about and less likely to
drift.

## Why

The repo currently uses both:

- `den/inventory/*` for exported output composition
- `lib/hosts.nix` for SSH, DNS, public ingress, DHCP reservations, and related
  operational metadata

That works, but it creates a source-of-truth split. The repo already has checks
to keep them aligned, which is a sign that the boundary is important but still
easy to get wrong.

## Scope

- document the current authority split between `den/inventory` and
  `lib/hosts.nix`
- identify metadata that could be moved or normalized without destabilizing the
  repo
- propose or implement one small improvement that reduces drift pressure
- add comments where the split is intentional and should remain

## Non-Goals

- rewriting the inventory model from scratch
- moving all DNS/SSH/public ingress logic into den in one PR
- changing router service behavior as part of a metadata cleanup

## Validation

- docs/comments make the boundary clear
- inventory-related checks still pass
- one concrete drift-prone edge is improved or explicitly documented
