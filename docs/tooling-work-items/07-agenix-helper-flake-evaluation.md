# 07 Agenix Helper Flake Evaluation

Status: `done`

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

## Findings

Based on the current repo state, most agenix-related helpers are still
migration-layer or repo-policy logic rather than clean reusable abstractions.
Notable patterns:

- `modules/helpers/optional-secrets.nix`: small pure helper, used across several
  host modules, no migration branches. This is the only strong extractable
  candidate today.
- user-scoped activation (`modules/home-manager/agenix-user-secrets.nix`) and
  token fallbacks (`modules/home-manager/user-secrets.nix`, fnox seed sources,
  secrets inventory in `secrets.nix`) are stable enough locally but tightly
  coupled to this repo’s secret naming, paths, and migration history.
- machine-identity helpers (`modules/nixos/common/agenix-machine-identity.nix`,
  `lib/agenix-machine-identities.nix`) are a good shape but embedded in a
  larger, repo-specific bootstrap and migration story.

## Recommendation and Threshold

- **Current recommendation:** stay local for now. Do **not** publish a helper
  flake yet.
- Treat `modules/helpers/optional-secrets.nix` as the only flake-ready surface,
  but keep it in-repo until more consumers exist.
- For extraction to be justified, require at least:
  - the same `optional-secrets` API (or successor) used in ≥3 repos
  - removal of SOPS/legacy branches from user/token helpers
  - decoupling helper logic from repo-specific paths, host names, and
    environment policy

See `docs/agenix-helper-threshold.md` for a more detailed, repo-wide threshold
and follow-up guidance.

## Implementation

- Audited all agenix helper patterns across `modules/`, `lib/`, and host configs.
- Concluded: stay local for now; see Recommendation above and
  `docs/agenix-helper-threshold.md` for the extraction criteria.
- Moved `modules/helpers/optional-secrets.nix` to `lib/optional-secrets.nix` to
  signal it as the most stable and reusable pattern in the repo.
- Updated all five call sites (router and podman stack files) to the new path.

## Notes

Bias toward keeping things local unless there is a clearly repeated,
well-understood pattern across multiple repos. A premature flake extraction is
more likely to preserve migration debt than remove it.
