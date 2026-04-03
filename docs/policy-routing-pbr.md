# Policy-Based Routing (PBR) for Router

This document outlines the design and patterns for Policy-Based Routing (PBR) in the `unified-nix-configuration` router model, borrowing ideas from VyOS while maintaining NixOS/systemd-networkd simplicity.

## Goals

- Support per-interface and per-subnet routing policies (e.g., VPN egress).
- Enable complex traffic steering (e.g., specific destinations via VPN).
- Maintain management-plane independence (management traffic never uses PBR tables).

## Architecture

We use `systemd-networkd`'s `[RoutingPolicyRule]` and multiple routing tables to implement PBR.

### 1. Routing Tables
Standard tables used in this repo:
- `main` (254): Default routing table (WAN/connected routes).
- `200`: Primary VPN routing table.
- `300`: Secondary/Guest VPN routing table.

### 2. Policy Rules
Rules are assigned to interfaces in `routedInterfaces`:
- **Default Policy**: `policyRouting.enable = true;` routes ALL traffic from the interface through the specified table.
- **Specific Rules**: `policyRouting.rules` allowing steering traffic based on:
  - `to`: Destination prefix (CIDR).
  - `table`: Table to look up.
  - `priority`: Rule priority (lower is higher precedence).

## Recommended Patterns

### Pattern 1: Full Tunnel VPN (Privacy VLAN)
All traffic from a specific VLAN should exit via a VPN.
```nix
iot = {
  device = "enp6s16.20";
  vlanId = 20;
  ipv4Address = "10.20.20.1/24";
  policyRouting = {
    enable = true;
    table = 200; # Routes to wg0 default gateway
  };
};
```

### Pattern 2: Selective Steering (Guest/Split-Tunnel)
Most traffic uses WAN, but specific services (e.g., DNS) use VPN.
```nix
guest = {
  device = "enp6s16.30";
  ipv4Address = "10.30.30.1/24";
  policyRouting = {
    enable = false; # Default to WAN
    rules = [
      {
        to = "8.8.8.8/32";
        table = 300; # Route specific IP via VPN
        priority = 50;
      }
    ];
  };
};
```

## Guardrails

1.  **Management Plane Isolation**: Never apply PBR rules to the `management` interface. Control plane traffic must always use the `main` table to ensure reachability.
2.  **Priority Management**: Use priorities consistently. Default interface rules use priority `100`. Specific steering rules should use priorities `< 100` (e.g., `50`).
3.  **Default Routes**: Tables used for PBR (e.g., `200`, `300`) MUST have a default route (usually added by the VPN module).
4.  **MTU Consistency**: VPN interfaces often have lower MTU (e.g., `1420`). Ensure client interfaces using VPN tables are aware of this (MSS clamping is handled by `router-optimizations`).

## Implementation Details

The implementation lives in:
- `nix-router-optimized/modules/router-networking.nix`: Core PBR logic in `routedInterfaceModule`.
- `nix-router-optimized/modules/router-vpn.nix`: Populates routing tables with default routes from VPN peers.
