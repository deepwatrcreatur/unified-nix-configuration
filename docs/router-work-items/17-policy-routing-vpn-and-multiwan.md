# Policy Routing For VPN And Multi-WAN

Status: `in-progress`
Suggested branch: `feat/router-policy-routing-vpn-and-multiwan`
Priority: `medium`
Blocked By: `08-vlans-and-vpn-policy-routing.md`
Unblocks: future router multi-edge and split-routing work

## Goal

Design a minimal policy-based routing (PBR) layer for VPN and potential multi-WAN use cases, borrowing VyOS-style table and rule patterns while staying within the current homelab scope.

## Why This Matters

A small, well-scoped PBR design enables clean split-tunnel VPN behavior and future multi-WAN scenarios without overloading the main routing table or adding unnecessary enterprise complexity.

## Tasks

- Identify concrete homelab scenarios that need PBR (e.g., specific VLANs/hosts via VPN, future dual-ISP failover).
- Sketch routing-table and rule structure for those scenarios (what additional tables, how traffic is matched).
- Define where PBR configuration should live in router modules and how it interacts with existing firewall/NAT.
- Document recommended patterns and guardrails for adding new PBR rules.

## Validation

- Resulting design can be expressed as small, PR-sized follow-up items.
- PBR recommendations align with existing router invariants and interface-role model.
- No requirement for VRF/multi-tenant complexity beyond real homelab needs.
