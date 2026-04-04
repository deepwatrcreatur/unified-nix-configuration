# Ulogd Package Vs Design Alignment

Status: `ready`
Priority: `medium`
Branch: `docs/router-ulogd-design-alignment`

## Goal

Document and, if needed, lightly refactor the router flow-logging approach so
future agents stop assuming a richer `ulogd` plugin surface than Nixpkgs
actually provides.

## Why

The recent failure mode shows a recurring pattern:

- the router design assumes a particular `ulogd` stack layout
- the packaged plugin set in Nixpkgs does not fully match that assumption
- rebuilds then fail on service startup instead of degrading gracefully

That is partly a packaging mismatch, but partly a repo-organization problem:
the intended flow-logging design is not clearly constrained by what the package
supports.

## Scope

- document which `ulogd` plugins and stack shapes are known to work with the
  current packaged `ulogd`
- explain where router flow logging is configured today and which parts are
  authoritative
- decide whether unsupported plugins should be:
  - removed from the default design,
  - made optional,
  - or supplied via an overridden package
- leave concise code comments near the active config so future agents do not
  reintroduce unsupported plugin references casually

## Non-Goals

- building a custom observability platform
- replacing `ulogd` entirely in the same PR
- adding large dashboard or vector work unless a tiny note is needed for future
  follow-up

## Validation

- docs and comments clearly describe the supported `ulogd` stack
- follow-up agents can tell whether a missing plugin is a package problem or a
  repo-design problem
- the chosen default path is consistent with what `router` actually runs

## Notes

This is the follow-up hardening task after the immediate runtime repair. It
should reduce future drift between intent, package contents, and generated
configuration.
