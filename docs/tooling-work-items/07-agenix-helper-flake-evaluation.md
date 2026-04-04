# 07 Agenix Helper Flake Evaluation

Status: `ready`

Suggested branch: `docs/tooling-agenix-helper-flake-eval`

## Goal

Decide whether the repeated agenix-user-secret patterns in this repo are mature
enough to justify a separate reusable flake, or whether they should stay local
until the design is tighter.

## Why

This repo now has several agenix-adjacent helper patterns:

- user-scoped agenix secret activation
- agenix-first token/config fallbacks
- `fnox` secret source wiring
- host bootstrap expectations around machine identities

That looks like the beginning of a reusable abstraction, but spinning out a
flake too early could freeze a messy migration-layer API.

## Scope

- audit which agenix helper patterns are genuinely reused across hosts and
  repos versus being specific to this repo’s history
- identify the smallest coherent reusable surface, if any
- document the threshold for extraction:
  - what should remain local cleanup
  - what could become a separate flake later
- if extraction does look justified, sketch a minimal flake/module shape and
  migration plan rather than implementing it immediately

## Non-Goals

- publishing a new helper flake in this PR
- wrapping every secret workflow into a generic abstraction
- replacing `agenix` itself

## Validation

- recommendation is concrete: either “keep local for now” or “extract this
  minimal surface”
- follow-up agents can tell whether a new repo should depend on a helper flake
  or just copy the local pattern temporarily

## Notes

Bias toward keeping things local unless there is a clearly repeated,
well-understood pattern across multiple repos. A premature flake extraction is
more likely to preserve migration debt than remove it.
