# Work Item 40: Upstream nix-router-optimized Fixes and Downstream Cleanup

**Status:** done  
**Priority:** high  
**Created:** 2026-09-19  

## Goal

Upstream all host-local router fixes, systemd hardening overrides, and runtime repairs from `unified-nix-configuration` into the standalone `nix-router-optimized` flake repository, bump `flake.lock`, and remove redundant downstream monkeypatches.

## Context & Why This Matters

Several critical router fixes were applied directly to `unified-nix-configuration` (`hosts/nixos/router/role.nix`, `modules/nixos/router/`, `modules/nixos/router-dashboard-runtime-repair.nix`, and `scripts/router-dashboard-api-wrapper.py`) rather than upstream in `nix-router-optimized`:
1. **Pangolin Service Hardening:** Systemd `SocketBindDeny` adjustment, `.next` write permissions, DB JSON symlinks, and port 3001 collision avoidance.
2. **UDP GRO Forwarding:** `rx-udp-gro-forwarding on rx-gro-list off` in hardware offload initialization.
3. **Kea DHCP Hardening:** `match-client-id = false`, `decline-probation-period = 300`, `expired-leases-processing`, startup header check, and carrier wait.
4. **Ulogd Flow Logging:** `LOGEMU` support for vanilla Nixpkgs without requiring the custom JSON overlay.
5. **Router Dashboard Runtime Repair:** Deprecating the 497-line Python API monkeypatch wrapper and snapshot services by integrating them upstream.
6. **Grafana Secret Key:** File-backed secret key for NixOS 26.05+ compatibility.

This creates severe maintenance drift and prevents upstream users of `nix-router-optimized` from benefiting from these fixes.

## Scope

### Phase 1: Upstream Implementation in `nix-router-optimized`
Tracked under upstream work items:
- Work Item 100: Upstream Router Pangolin Service Hardening & Port Configuration
- Work Item 101: Upstream UDP GRO Forwarding Offload Configuration
- Work Item 102: Upstream Kea DHCPv4 Hardening, Pool Exhaustion Protection, and Carrier Readiness
- Work Item 103: Upstream Ulogd LOGEMU Output Support
- Work Item 104: Upstream File-Backed Grafana Secret Key
- Work Item 105: Upstream Router Dashboard API Hardening & Snapshot Handlers

### Phase 2: Downstream Cleanup in `unified-nix-configuration`
- Update `flake.lock` (`nix flake lock --update-input nix-router-optimized`).
- Remove `modules/nixos/router-dashboard-runtime-repair.nix` and `scripts/router-dashboard-api-wrapper.py`.
- Remove downstream `lib.mkForce` overrides in `hosts/nixos/router/role.nix` for Pangolin, Kea settings, hardware offload, and ulogd.
- Transition IPv6 RA suppression on `router-backup` to declarative `services.router-networking.routedInterfaces.<name>.ipv6SendRA = false`.

## Validation

- `nix eval .#nixosConfigurations.router.config.system.build.toplevel` succeeds without errors.
- `nix eval .#nixosConfigurations.router-backup.config.system.build.toplevel` succeeds without errors.
