# VPN Module Hardening Plan

This plan details the upstream hardening tasks for `nix-router-optimized` VPN modules based on recent review feedback.

## Ranked Task List

### 1. Centralize WAN Derivation Helper
- **Goal**: Eliminate redundant `wanInterfaces` derivation logic across `router-wireguard`, `router-openvpn`, and `router-tailscale`.
- **Location**: Upstream `lib` or a shared helper module in `nix-router-optimized`.
- **Implementation**: Create a function that takes `config` and returns the prioritized list of WAN devices (from `router-firewall` or `router-optimizations`).

### 2. Guardrails for `routeToWan` No-Op Cases
- **Goal**: Warn users when `routeToWan = true` but no WAN interfaces are defined or `router-firewall` is disabled.
- **Implementation**: Add `warnings` or `assertions` to each VPN module that detect these mismatched states.

### 3. OpenVPN Interface Name Validation
- **Goal**: Prevent silent collisions or misconfigurations in `router-openvpn` instances.
- **Implementation**: Add an assertion that ensures all `instances.*.interfaceName` values are unique and follow valid Linux naming conventions.

### 4. Integration Tests for VPN Egress
- **Goal**: Ensure `routeToWan` actually generates the expected `nftables` rules.
- **Implementation**: Add a NixOS integration test in `nix-router-optimized` that evaluates a minimal router with one VPN module and checks the resulting firewall ruleset.

### 5. Module Selection Decision Matrix
- **Goal**: Help users choose between `router-wireguard`, `router-openvpn`, `router-tailscale`, and the new generic `router-vpn`.
- **Location**: Upstream `README.md` or a new `VPN.md` doc.

## Task Details

| Task | Suggested Branch | Scope |
| :--- | :--- | :--- |
| WAN Helper | `refactor/vpn-wan-helper` | Upstream Module |
| Guardrails | `feat/vpn-guardrails` | Upstream Module |
| OpenVPN Validation | `fix/openvpn-validation` | Upstream Module |
| Integration Tests | `test/vpn-integration` | Upstream Tests |
| Decision Matrix | `docs/vpn-decision-matrix` | Upstream Docs |

## Suggested Test Scope

- **Unit**: Verify `wanInterfaces` helper returns correct devices for various `router-firewall` configs.
- **Integration**: `nix build .#checks.x86_64-linux.vpn-egress` (new test).
- **Manual**: Verify `warnings` appear in `nixos-rebuild` when WAN is missing but `routeToWan` is enabled.
