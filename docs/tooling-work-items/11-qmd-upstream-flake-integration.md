# 11 Qmd Upstream Flake Integration

Status: `ready`

Suggested branch: `feat/tooling-qmd-upstream-flake`

## Goal

Add `tobi/qmd` to the systems configuration by consuming its upstream flake
directly, then expose it where it is useful by repo and host role.

## Why

`qmd` already ships a `flake.nix`, so this repo should use the upstream flake
instead of creating another packaging repo unless a real patch fork is needed
later.

## Scope

- add `tobi/qmd` as a flake input
- decide the right integration layer for exposing `qmd`
- enable it for the systems or shells where repo-local knowledge search is
  useful
- add short docs on when agents should prefer `qmd` over ad hoc text search

## Non-Goals

- creating a separate Nix packaging repo for `qmd`
- deploying `qmd` everywhere without a host-role decision
- building a full MCP rollout in the same PR unless the repo already has a
  clean place for it

## Validation

- flake evaluation still works after adding the upstream input
- `qmd` is available in the intended package set or shell path
- docs make it clear that the repo consumes the upstream flake directly
