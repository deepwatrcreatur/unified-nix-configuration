# Router Cutover Validation Hardening

Status: `done`
Priority: `medium`
Branch: `fix/router-cutover-validation-hardening`

## Goal

Make the router cutover validation script target the correct management path and
return a meaningful exit code for blocking failures.

## Why

Review feedback on the initial validation script highlighted two operator-facing
problems:

- diagnostics should target the router management endpoint, not the production
  LAN address by default
- blocking failures currently print error text but do not necessarily return a
  failing exit status

That makes the script less useful for automation and for remote troubleshooting
through the management plane.

## Scope

- switch SSH-based checks to a management-plane hostname or address, ideally
  derived from repo data rather than duplicated literals
- add an explicit exit-code path for blocking validation failures
- keep advisory-only checks non-fatal
- verify whether any shell-compatibility review comments are actually relevant
  to the intended Bash execution model before changing shells or syntax

## Non-Goals

- replacing the script with a full integration test harness
- broad router observability redesign
- changing the intended validation surface beyond the identified review gaps

## Validation

- the script passes `bash -n`
- a simulated blocking failure returns non-zero
- advisory-only failures can still be reported without turning the whole run
  into a false hard failure
