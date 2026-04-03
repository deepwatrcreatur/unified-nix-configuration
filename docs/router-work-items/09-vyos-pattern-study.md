# VyOS Pattern Study

Status: `ready`
Suggested branch: `docs/router-vyos-pattern-study`
Priority: `low`

## Goal

Study the VyOS codebase and documentation for router-modeling ideas that are
worth borrowing into this repo's NixOS router structure.

## Why This Matters

VyOS is a router-first declarative system with stronger built-in structure for:

- interface roles
- firewall and NAT modeling
- policy routing
- VPN configuration
- operator diagnostics and recovery

We do not want to adopt VyOS or recreate its CLI. We do want to identify the
parts of its design that would improve this repo's router modules and planning.

## Scope

This is a study and recommendation task, not a platform migration task.

The output should be:

- a concise comparison between current repo patterns and VyOS patterns
- a ranked list of ideas worth borrowing
- a recommendation for which ideas should become future router work items
- explicit notes on what should *not* be copied

## Questions To Answer

- How does VyOS model interface roles and dependencies?
- How does VyOS separate management/control-plane concerns from data-plane
  forwarding?
- What NAT/firewall/policy-routing structure is worth imitating?
- What diagnostics/health model ideas would improve the router dashboard or
  operator workflow here?
- Which VyOS ideas are overkill for a homelab and should be ignored?

## Relevant Local Files

- [`docs/router-work-items/README.md`](./README.md)
- [`docs/router-work-items/05-router-health-model.md`](./05-router-health-model.md)
- [`docs/router-work-items/06-boot-and-recovery-hardening.md`](./06-boot-and-recovery-hardening.md)
- [`docs/router-work-items/08-vlans-and-vpn-policy-routing.md`](./08-vlans-and-vpn-policy-routing.md)
- router role and common modules under `hosts/nixos/router/` and `modules/nixos/router/`

## Deliverable

Add a short design note under `docs/` or expand this work-item file with:

- useful patterns to borrow now
- useful patterns to defer
- patterns to reject
- concrete follow-up PR ideas, if any

## Do Not

- do not migrate to VyOS
- do not introduce enterprise-only complexity just because VyOS has it
- do not block current recovery/stability work on this study
