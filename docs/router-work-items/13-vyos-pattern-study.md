Status: `done`
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

## Findings

### Patterns to Borrow

- **Interface role tagging and zones**: Treat interfaces as roles (WAN, LAN, DMZ) with clear descriptions and attach firewall policies to roles, not raw device names, similar to VyOS zone-based firewalling.
- **Direction-scoped firewall rule sets**: Maintain explicit `in`/`out`/`local` rule sets per interface role (e.g., LAN_IN, WAN_LOCAL) to keep packet-flow intent obvious and make future policy-routing work easier.
- **Policy-based routing tables for special traffic**: Use dedicated routing tables for specific traffic classes (e.g., VPN egress, future multi-WAN) instead of overloading the main table, borrowing VyOS-style PBR patterns.
- **Operator-focused diagnostics**: Ensure router-dashboard and CLI affordances answer the same questions VyOS focuses on (`show firewall`, `show nat`, `show policy route` style views) so operators can see which policy or table is in effect.

### Patterns to Defer

- **Full zone-based firewall abstraction**: Keep the existing nftables-based structure for now and only move toward a full zone abstraction once the current router module boundaries are more stable.
- **Highly complex multi-VRF topologies**: Defer VRF-style segmentation and provider-grade policy routing until there is a concrete homelab need beyond the existing single-router, single-edge model.

### Patterns to Reject

- **Overly interactive CLI-centric workflows**: Do not replicate VyOS’s interactive configuration/commit model; keep the declarative Nix approach as the source of truth and use dashboards/just recipes for operations instead.
- **Enterprise-only inspection stacks**: Avoid importing heavy, enterprise-grade inspection tooling that would significantly increase complexity without clear benefit for this homelab.

### Follow-Up Ideas

- Add a future work item to tighten the mapping between interface roles (WAN/LAN/management) and firewall rule sets, making the role-based intent as obvious as VyOS’s zone model.
- Add a future work item to design a minimal policy-based-routing layer for VPN and multi-WAN use cases, grounded in the homelab’s concrete traffic patterns.

## Validation

- the work-item file is updated with findings
- any newly discovered work is captured as follow-up queue items instead of
  being left only in chat or PR comments
