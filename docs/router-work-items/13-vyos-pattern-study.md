Status: in-progress
Priority: low
Branch: docs/router-vyos-pattern-study
Blocked By: none
Unblocks: future router module-boundary cleanup

# VyOS Pattern Study

## Goal

Study the VyOS codebase and docs for router-architecture ideas worth borrowing
into this repo without turning the work into a platform migration.

## Why

VyOS is a mature router-first system with clear patterns around interface-role
modeling, firewall/NAT boundaries, policy routing, and operator-facing
diagnostics. Some of those patterns may improve this repo's router structure.

## Scope

- identify concrete VyOS ideas worth borrowing
- rank them as `borrow`, `defer`, or `reject`
- keep recommendations grounded in this homelab's real needs

## Focus Areas

- interface role modeling
- management/control-plane separation
- firewall/NAT/policy-routing structure
- diagnostics and operator workflow

## Constraints

- do not treat this as a migration plan
- do not add enterprise-only complexity without clear homelab payoff
- prefer actionable follow-up ideas over abstract comparison

## Deliverables

- a short study note with:
  - patterns to borrow
  - patterns to defer
  - patterns to reject
- any follow-up work items that should be added to this queue

## Validation

- the work-item file is updated with findings
- any newly discovered work is captured as follow-up queue items instead of
  being left only in chat or PR comments
