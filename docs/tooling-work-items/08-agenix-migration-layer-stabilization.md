# 08 Agenix Migration Layer Stabilization

Status: `in-progress`

Suggested branch: `refactor/tooling-agenix-migration-layer`

## Goal

Tighten the repo’s agenix-related helper layer until it reflects a stable
agenix-first design rather than a mix of active behavior and migration-era
compatibility paths.

## Why

Right now the repo’s agenix story is partly reusable and partly transitional:

- agenix is the active secret backend
- but some user activation, token fallback, and wrapper-seed logic still carries
  SOPS-era compatibility behavior
- that makes it hard to tell which helper patterns are stable enough to reuse
  across repos

Before considering extraction into a helper flake, the local design should be
made more coherent.

## Scope

- audit agenix-related helper logic in active modules
- separate stable agenix-first behavior from temporary migration/fallback logic
- simplify or annotate the migration-layer code so future agents can tell which
  parts are authoritative
- prefer small cleanup changes that reduce ambiguity over broad redesign

## Non-Goals

- publishing a new helper flake
- removing every compatibility path in one PR
- redesigning all secret-consuming applications at once

## Validation

- active agenix-first hosts still evaluate cleanly
- helper modules and comments make the intended agenix-first path obvious
- future extractions can point at a smaller and more stable local surface

## Notes

This is the cleanup step that should happen before any serious extraction
decision. A reusable flake built before this work would likely preserve
migration debt instead of removing it.
