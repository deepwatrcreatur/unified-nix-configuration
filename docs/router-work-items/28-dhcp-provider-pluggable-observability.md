# DHCP Provider Pluggable Observability

Status: `ready`
Suggested branch: `design/router-dhcp-provider-observability`
Priority: `medium`

## Goal

Design the provider boundary for DHCP observability so the router dashboard and
related diagnostics can report leases and DHCP health correctly whether the
router is using Technitium or Kea.

## Why This Matters

The current dashboard and diagnostics implicitly assume Technitium is the DHCP
engine. That assumption will not survive a clean Kea transition, and it is
already creating coupling between:

- DHCP provider selection in router config
- lease reporting in the dashboard
- DHCP health/operator workflows

If the provider is meant to be switchable, the observability/reporting layer
also needs an explicit provider boundary instead of hardcoded Technitium API
calls.

## Questions To Answer

- what DHCP-provider choice should be surfaced by `nix-router-optimized`:
  - existing router DNS/DHCP provider shape
  - a separate DHCP-specific provider option
- what should the dashboard consume:
  - a unified local JSON/state artifact
  - a provider-specific backend adapter
  - direct provider-specific API calls behind a common interface
- what is the minimum lease/status model that should be provider-agnostic
- which fields are provider-specific and should degrade gracefully
- should `router-diag` and dashboard share the same abstraction

## Tasks

- inspect the existing provider/config shape in `nix-router-optimized`
- define a provider-neutral data model for:
  - lease list
  - reservation visibility
  - scope/subnet summary
  - provider availability/error state
- recommend where the abstraction should live:
  - dashboard backend only
  - separate upstream module/library/script
  - generated state file(s)
- identify what would need to change for Kea support without implementing Kea
- split any resulting implementation into future PR-sized work items

## Constraints

- this is a design task, not a full implementation task
- do not assume Technitium remains the only provider
- do not force Kea-specific concepts into the generic interface unless they
  clearly belong there

## Validation

- the design makes it obvious how the dashboard would select Technitium vs Kea
- follow-up implementation tasks are concrete and separable
- the proposal fits the current `nix-router-optimized` module boundaries or
  explains what should change upstream

## Deliverable

- branch commit(s)
- concise design note and follow-up task breakdown
