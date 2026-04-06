# Router Source of Truth

This document maps where each router concern lives so agents know which file
to edit first and which files are legacy mirrors or wiring glue.

Both `router` and `router-backup` are `mode = "aspect"` entries in
`den/inventory/hosts.nix`. Their outputs flow through `mkInventoryOutputs`.

---

## Import graph

### router

```
den/inventory/hosts.nix          ← entry point; declares aspects and hostPath
  └─ den/hosts/router/           ← hostPath
       └─ default.nix            ← mkInventoryHostModule wiring
            ├─ den aspects (via aspectsList)
            │    ├─ nixos-base
            │    ├─ home-manager-users
            │    ├─ github-token-client
            │    └─ router-router
            │         └─ den/aspects/router-router.nix
            │              ├─ inputs.disko.nixosModules.disko
            │              ├─ inputs.nix-router-optimized.nixosModules.router-networking
            │              ├─ inputs.nix-router-optimized.nixosModules.router-firewall
            │              ├─ inputs.nix-router-optimized.nixosModules.router-dns-service
            │              ├─ inputs.nix-router-optimized.nixosModules.router-homelab
            │              ├─ inputs.nix-router-optimized.nixosModules.router-log-storage
            │              ├─ inputs.nix-router-optimized.nixosModules.router-optimizations
            │              ├─ inputs.nix-router-optimized.nixosModules.router-tailscale
            │              ├─ inputs.nix-router-optimized.nixosModules.router-observability
            │              ├─ inputs.nix-router-optimized.nixosModules.router-vpn
            │              ├─ modules/nixos/common
            │              ├─ modules/nixos/services/iperf3.nix
            │              ├─ modules/nixos/keyboard-glitches.nix
            │              ├─ modules/nixos/snap.nix
            │              └─ modules/activation-scripts
            ├─ primaryUserImports
            │    └─ users/deepwatrcreatur/hosts/router/  ← user overlay
            └─ extraImports  (legacy host-local files, not yet den aspects)
                 ├─ hosts/nixos/router/hardware-configuration.nix
                 ├─ hosts/nixos/router/networking.nix
                 ├─ hosts/nixos/router/caddy.nix
                 ├─ hosts/nixos/router/disko.nix
                 └─ hosts/nixos/router/configuration.nix
                      ├─ hosts/nixos/router/role.nix  (called as function with host args)
                      └─ hosts/nixos/router/dns-zone.nix  (inline import)
```

### router-backup

```
den/inventory/hosts.nix          ← entry point
  └─ den/hosts/router-backup/    ← hostPath
       └─ default.nix            ← mkInventoryHostModule wiring
            ├─ den aspects (same aspectsList as router)
            │    └─ router-router  ← same den/aspects/router-router.nix
            ├─ primaryUserImports
            │    └─ users/deepwatrcreatur/hosts/router-backup/default.nix
            └─ extraImports  (legacy host-local files)
                 ├─ hosts/nixos/router-backup/hardware-configuration.nix
                 ├─ hosts/nixos/router/networking.nix  (shared; hostName override applied below)
                 ├─ hosts/nixos/router/caddy.nix  (shared; wrapper inlined into den leaf)
                 └─ hosts/nixos/router-backup/configuration.nix
                      ├─ inputs.disko.nixosModules.disko
                      ├─ hosts/nixos/router-backup/disko.nix
                      └─ hosts/nixos/router/role.nix  (backup-specific args)
```

---

## Per-concern source of truth

| Concern | Active file | Notes |
|---------|-------------|-------|
| Hardware config (router) | `hosts/nixos/router/hardware-configuration.nix` | Generated; never edit manually |
| Hardware config (backup) | `hosts/nixos/router-backup/hardware-configuration.nix` | Generated; never edit manually |
| Hostname | `hosts/nixos/router/networking.nix` | Sets `hostName = "router"`; backup wrapper overrides to `"router-backup"` |
| DNS service (Technitium) | `hosts/nixos/router/networking.nix` | Config applies to both hosts via shared import |
| NAT policy | `hosts/nixos/router/networking.nix` | `networking.nat.enable = false`; nftables handles NAT in role.nix |
| Disk layout (router) | `hosts/nixos/router/disko.nix` | Hardware-adjacent; keep separate |
| Disk layout (backup) | `hosts/nixos/router-backup/disko.nix` | Imported by `configuration.nix`; hardware-adjacent, keep separate |
| Caddy / ingress | `hosts/nixos/router/caddy.nix` | Both hosts share this file directly |
| Router role (networking, firewall, DNS, observability, VPN) | `den/aspects/router-router.nix` + upstream `nix-router-optimized` modules | The den aspect selects which upstream modules to import |
| Host-specific role args (WAN/LAN devices, IPs, Grafana paths) | `hosts/nixos/router/configuration.nix` and `hosts/nixos/router-backup/configuration.nix` | Each calls `role.nix` as a function with per-host arguments |
| NIC stable names | `hosts/nixos/router/configuration.nix` (MAC-based) and `hosts/nixos/router-backup/configuration.nix` (PCI path-based) | Separate rules because the two machines use different matching strategies |
| DNS zone data (static hosts, aliases) | `hosts/nixos/router/dns-zone.nix` | Inline-imported by `configuration.nix`; edit here to manage DNS records |
| ulogd flow logging | `hosts/nixos/router/role.nix` (via nix-router-optimized) | Uses LOGEMU plugin (base `pkgs.ulogd`); JSON plugin requires overlay — not active by default |
| User overlay | `users/deepwatrcreatur/hosts/router/` and `users/deepwatrcreatur/hosts/router-backup/default.nix` | Applied via `primaryUserImports` in each den leaf |

---

## Where to land fixes

- **DNS / hostname changes**: `hosts/nixos/router/networking.nix`. Topology-derived
  values (domain name, IP ranges) live in `config.router.topology`; see
  `docs/network-source-of-truth.md` for that layer.
- **Firewall / NAT / observability / VPN**: tune options provided by
  `nix-router-optimized` modules; the entry point is `den/aspects/router-router.nix`.
- **Caddy virtualHosts, ACME, DDNS**: `hosts/nixos/router/caddy.nix`.
- **DNS zone records**: `hosts/nixos/router/dns-zone.nix`.
- **Per-host role parameters** (device names, IPs, Grafana paths):
  `hosts/nixos/router*/configuration.nix` for the relevant host.
- **New shared router behaviour**: add a den aspect under `den/aspects/` and reference
  it in both `router` and `router-backup` `aspectsList` entries in
  `den/inventory/hosts.nix`.
- **Hardware**: regenerate `hardware-configuration.nix` on the target machine with
  `nixos-generate-config`; never edit the generated file.

---

## Legacy files still active (migration status)

All `extraImports` in both den leaves are legacy files not yet represented as den
aspects. The table below summarises migration readiness.

| File | Reason still separate | Migration candidate? |
|------|-----------------------|---------------------|
| `hosts/nixos/router/hardware-configuration.nix` | Generated hardware config | No — keep separate always |
| `hosts/nixos/router/networking.nix` | Reads `config.router.topology` at module eval time; cannot be a static den aspect without topology-aware aspect support | Yes, once topology config moves to den |
| `hosts/nixos/router/caddy.nix` | 194 lines; large host-local file | No urgent need; keep separate |
| `hosts/nixos/router/disko.nix` | Disk layout; hardware-adjacent | No — keep separate always |
| `hosts/nixos/router/configuration.nix` | Wires `role.nix` with host-specific args; needs den aspect function-call pattern | Yes — long-term goal once role.nix API stabilises |
| `hosts/nixos/router-backup/hardware-configuration.nix` | Generated hardware config | No |
| `hosts/nixos/router-backup/networking.nix` | Thin wrapper: imports `router/networking.nix` and overrides hostname | Yes — trivial to inline into den leaf |
| `hosts/nixos/router-backup/caddy.nix` | Single line re-export of `router/caddy.nix` | Yes — can inline the import into den leaf |
| `hosts/nixos/router-backup/configuration.nix` | Wires `role.nix` with backup args | Yes — same migration path as `router/configuration.nix` |
