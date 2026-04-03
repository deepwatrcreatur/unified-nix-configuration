# Observability And Flow Logging

Status: `in-progress`
Suggested branch: `feat/router-flow-logging`
Priority: `medium`

## Goal

Borrow the strongest observability ideas from other Nix routers once the basic
recovery and interface hardening work is complete.

## Good Ideas To Borrow

- flow logging with `ulogd`
- optional log/metric routing via `vector`
- richer firewall visibility
- optional traffic analysis tooling beyond the current dashboard stack

## Why This Is Blocked

This is lower value than interface/recovery work and should not start until the
router is stable again.

## Tasks

- assess whether `ulogd` + `vector` fits your repo better than a larger
  appliance-style stack
- keep this optional and modular
- avoid coupling to one host’s exact dashboard choices

## Validation

- logs/metrics exist without destabilizing the router role

## Do Not

- do not start before the top five items are addressed
