# Router Dashboard Review Hardening

Status: `ready`
Priority: `high`
Branch: `fix/router-dashboard-review-hardening`

## Goal

Resolve the concrete post-review hardening issues in the router-dashboard
wrapper path without reopening the broader runtime-repair design.

## Why

The runtime repair restored service behavior, but review feedback identified a
small set of correctness and operability gaps that should be handled in a
follow-up PR before more changes pile on top:

- unsafe handling of missing interface state values
- weak validation/logging around environment and file reads
- fail2ban snapshot subprocess exceptions can crash the helper
- the runtime module should make group ownership assumptions explicit
- the snapshot service privilege model should be reviewed and tightened if
  feasible

These are good follow-up tasks because they are narrow, testable, and directly
related to the repaired runtime path.

## Scope

- harden `router-dashboard-api-wrapper.py` against missing env vars and missing
  interface state data
- log unexpected parse/read failures instead of silently swallowing them
- make the fail2ban snapshot helper degrade cleanly on subprocess exceptions
- ensure any tmpfiles ownership assumptions about `router-dashboard` are backed
  by explicit user/group definitions or documented upstream guarantees
- review whether the snapshot unit can run with less privilege without breaking
  access to `fail2ban-client`

## Non-Goals

- replacing the upstream dashboard entirely
- broad router-dashboard refactors unrelated to the review findings
- unrelated UI or data-model enhancements

## Validation

- `python -m py_compile` passes for the wrapper scripts
- the NixOS module still evaluates cleanly
- missing/malformed runtime inputs degrade gracefully instead of throwing 500s

## Notes

This item should verify each review comment against the current branch state
and only implement the fixes that are still truly needed.
