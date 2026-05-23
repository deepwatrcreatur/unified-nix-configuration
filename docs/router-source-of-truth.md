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
                 ├─ hosts/nixos/router/service-capability.nix
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
| Hostname | `hosts/nixos/router/networking.nix` and `den/hosts/router-backup/default.nix` | Primary hostname lives in `router/networking.nix`; backup hostname is forced in its den leaf |
| Shared DNS/NTP capability | `hosts/nixos/router/service-capability.nix` | Shared router service capability imported by both hosts |
| NAT policy | `hosts/nixos/router/service-capability.nix` | `networking.nat.enable = false`; nftables handles NAT in role.nix |
| Disk layout (router) | `hosts/nixos/router/disko.nix` | Hardware-adjacent; keep separate |
| Disk layout (backup) | `hosts/nixos/router-backup/disko.nix` | Imported by `configuration.nix`; hardware-adjacent, keep separate |
| Caddy / ingress | `hosts/nixos/router/caddy.nix` | Both hosts share this file directly; public DDNS ownership is gated by `router.failover.activeOwner` |
| Router role (networking, firewall, DNS, observability, VPN) | `den/aspects/router-router.nix` + upstream `nix-router-optimized` modules | The den aspect selects which upstream modules to import |
| Host-specific role args (WAN/LAN devices, IPs, Grafana paths) | `hosts/nixos/router/configuration.nix` and `hosts/nixos/router-backup/configuration.nix` | Each calls `role.nix` as a function with per-host arguments |
| Active single-owner identity | `modules/nixos/router/common.nix` via `router.failover.activeOwner` | Defaults to `true` on `router`, `false` on `router-backup`; currently gates public DDNS ownership, `kea-dhcp4-server` / `kea-dhcp-ddns-server` startup, `services.router-upnp.enable`, and `services.router-ntp.enable`, while LAN DNS remains a shared Technitium capability |
| NIC stable names | `hosts/nixos/router/configuration.nix` (MAC-based) and `hosts/nixos/router-backup/configuration.nix` (PCI path-based) | Separate rules because the two machines use different matching strategies |
| DNS zone data (static hosts, aliases) | `hosts/nixos/router/dns-zone.nix` | Inline-imported by `configuration.nix`; edit here to manage DNS records |
| ulogd flow logging | `hosts/nixos/router/role.nix` (via nix-router-optimized) | Uses LOGEMU plugin (base `pkgs.ulogd`); JSON plugin requires overlay — not active by default |
| User overlay | `users/deepwatrcreatur/hosts/router/` and `users/deepwatrcreatur/hosts/router-backup/default.nix` | Applied via `primaryUserImports` in each den leaf |

---

## Where to land fixes

- **DNS / NTP shared capability**: `hosts/nixos/router/service-capability.nix`.
- **Primary hostname / domain defaults**: `hosts/nixos/router/networking.nix`.
- **Active single-owner identity**: `modules/nixos/router/common.nix` via
  `router.failover.activeOwner`.
- **Shared LAN DNS / Technitium clustering boundary**:
  `hosts/nixos/router/service-capability.nix`.
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

## Current `activeOwner` Consumers

`router.failover.activeOwner` currently has a narrow, explicit consumer-side
meaning:

- in `hosts/nixos/router/caddy.nix`, it gates public Cloudflare DDNS ownership
- in `hosts/nixos/router/role.nix`, it gates `kea-dhcp4-server.service` startup
- in `hosts/nixos/router/role.nix`, it gates `kea-dhcp-ddns-server.service`
  startup
- in `hosts/nixos/router/role.nix`, it gates `services.router-upnp.enable`
- in `hosts/nixos/router/role.nix`, it gates `services.router-ntp.enable`

`services.router-dns-service` is intentionally **not** an `activeOwner`
consumer today. The consumer tree treats LAN-facing DNS service as a shared
Technitium capability on both routers, with clustering used to keep DNS/admin
state aligned, while DHCP failover and public DDNS ownership remain separate
boundaries.

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
