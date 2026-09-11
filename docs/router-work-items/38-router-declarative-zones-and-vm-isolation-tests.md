# Router Declarative Zones DSL & VM Isolation Test Suite

Status: `ready`
Priority: `medium`
Branch: `feat/router-declarative-zones-and-tests`

## Goal

Adopt the declarative zone abstraction and NixOS VM isolation test suite pattern
from the `blue-ridge` dotfiles repository
(`https://gitlab.com/usmcamp0811/dotfiles/-/tree/nixos/systems/x86_64-linux/blue-ridge`)
into `nix-router-optimized` and `unified-nix-configuration`.

## Why

1. **Declarative Zone DSL**:
   Currently, VLAN routing rules (LAN, IoT VLAN 20, Guest VLAN 30) require
   manual nftables snippets and policy routing wiring. The `blue-ridge`
   approach defines zones and allowed cross-zone traffic declaratively:
   ```nix
   router.zones = {
     lan   = { vlanId = 1;  isolation = "none"; };
     iot   = { vlanId = 20; isolation = "full"; };
     guest = { vlanId = 30; isolation = "full"; };
   };

   interZoneRoutes = [
     { from = "iot"; to = [ "lan" ]; protocol = "tcp"; ports = [ 8123 ]; description = "Home Assistant"; }
   ];
   ```
   This eliminates repetitive boilerplate and prevents inadvertent firewall
   leaks between untrusted IoT/Guest networks and internal infrastructure.

2. **Automated VM Isolation Testing**:
   `blue-ridge` uses NixOS VM integration tests (`checks/router-network-isolation`)
   that spin up virtual client nodes across LAN, IoT, and WAN in a Nix test
   harness. The test verifies that:
   - LAN can access Internet and IoT
   - IoT cannot reach LAN management or other nodes (except allowed ports)
   - Guest cannot reach private subnets
   Running this in CI prevents firewall regressions before code reaches physical
   routers.

## Scope

- In `nix-router-optimized`:
  - Enhance `modules/router-zones.nix` with clean inter-zone route rule syntax
    and automatic nftables chain generation.
  - Add `tests/router-network-isolation.nix` test harness.
- In `unified-nix-configuration`:
  - Migrate router VLAN rules in `hosts/nixos/router/role.nix` to use the
    declarative zone syntax.
  - Wire the test check into `outputs/checks.nix`.

## Non-Goals

- Replacing existing CAKE SQM, BBR, or Keepalived failover mechanisms.
- Changing production IP assignments or VLAN tag IDs (VLAN 20 for IoT, VLAN 30 for Guest).

## Validation

- `nix flake check` or `nix build .#checks.x86_64-linux.router-network-isolation` passes.
- Generated `nftables.rules` properly enforces inter-zone boundaries.
- Live router maintains full connectivity on LAN and appropriate isolation on VLANs.
