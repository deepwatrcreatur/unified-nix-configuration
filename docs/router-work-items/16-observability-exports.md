# Observability Exports

Status: `done`
Suggested branch: `feat/router-observability-exports`
Priority: `medium`

## Goal

Add standardized export capabilities to the `router-observability` module to
ship metrics and flow logs to a central homelab stack.

## Why This Matters

Currently, router observability is host-local. To make this data useful for
long-term analysis and central alerting, the router needs to push its state
out without creating a hard dependency on the central stack being "up".

## Tasks

- add optional Prometheus remote write support to `router-observability.nix`
- add optional Vector upstream sink support for shipping parsed flow logs
- ensure export traffic is compatible with management-plane-only routing
- add basic retry/buffering defaults so router services don't block if the
  destination is unreachable

## Deliverable

- updated `router-observability` module with export toggles
- documentation for the required central-stack receiver settings

## Validation

- local router eval/build
- verify that enabling exports does not break the local dashboard
- one smoke check proving the new options exist in `nix-instantiate`

## Do Not

- do not make external exports mandatory for local observability
- do not use the production LAN interface for export traffic if management is
  available
