# Management Plane Smoke Validation

Status: `done`
Suggested branch: `feat/router-management-plane-smoke-validation`
Priority: `medium`

## Goal

Create a repeatable smoke-validation path for the management-plane recovery
model instead of relying only on manual operator checks.

## Why This Matters

The current router design depends heavily on management-plane independence.
Manual verification has been useful, but this should become a repeatable
pre-merge or post-build check.

## Tasks

- identify the smallest useful automated smoke checks, for example:
  - management IP present in rendered config
  - key services bind to `0.0.0.0` or management-usable addresses
  - router-dashboard links include management paths
- choose whether the first version should be:
  - a `just` recipe
  - a Nix eval/check
  - a small verification script
- keep manual ops docs, but back them with one automated path

## Deliverable

- one repeatable smoke-validation mechanism
- short docs explaining what it does and what it does not prove

## Do Not

- do not try to fully simulate WAN/LAN failure in the first version
- do not block on a full VM/integration test harness
