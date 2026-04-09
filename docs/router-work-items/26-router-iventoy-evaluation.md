# Router iVentoy Evaluation

Status: `done`
Priority: `medium`
Branch: `docs/router-iventoy-evaluation`

## Goal

Evaluate whether iVentoy is a suitable fit for the homelab PXE goal and record
how it would integrate, if at all, with the router-managed boot path.

## Why

iVentoy may provide a faster path to useful PXE-based ISO booting than building
all menuing and artifact orchestration from scratch, but it is not yet in the
repo plans and has not been evaluated against the current Nix/router model.

Without a dedicated work item, future PXE work risks either ignoring iVentoy
entirely or making premature assumptions about how it should be deployed.

## Scope

- evaluate iVentoy conceptually against the homelab use case:
  - ad hoc ISO booting
  - mixed BIOS/UEFI clients
  - router-hosted versus separate-service deployment
- note packaging and operational questions for Nix/NixOS integration
- compare iVentoy to a simpler native PXE/TFTP/HTTP path where relevant
- recommend one of:
  - pursue iVentoy as a near-term implementation target
  - keep iVentoy as a later optional path
  - reject iVentoy for this repo and explain why
- capture risks, unknowns, and any upstream packaging gaps

## Non-Goals

- packaging iVentoy in this PR
- deploying a production PXE service immediately
- turning this into a broad survey of every netboot product

## Validation

- the repo has an explicit recorded decision about iVentoy direction
- follow-up PXE work can cite this evaluation instead of redoing the comparison
- the recommendation is grounded in this repo's operational model, not generic
  product marketing

## Notes

This item is intentionally evaluation-heavy. A clear "not now" outcome is still
useful if it reduces future thrash.

## Deliverable

The recommendation is documented in
[`docs/router-iventoy-evaluation.md`](../router-iventoy-evaluation.md).
