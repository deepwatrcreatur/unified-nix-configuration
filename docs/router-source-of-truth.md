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
| Caddy / ingress | `hosts/nixos/router/caddy.nix` | Both hosts share this file directly. Public ingress is currently pinned to the primary because WAN HA is disabled on both nodes until `router-backup` regains a real WAN NIC and that path is revalidated |
| Router role (networking, firewall, DNS, observability, VPN) | `den/aspects/router-router.nix` + upstream `nix-router-optimized` modules | The den aspect selects which upstream modules to import |
| Host-specific role args (WAN/LAN devices, IPs, Grafana paths) | `hosts/nixos/router/configuration.nix` and `hosts/nixos/router-backup/configuration.nix` | Each calls `role.nix` as a function with per-host arguments |
| Runtime single-owner LAN services | `hosts/nixos/router/role.nix` via `services.router-ha.singleActiveUnits` and `/run/router-ha/role` | The promoted node owns DDNS, DHCP, UPnP, and IPv6 RA runtime units; Chrony remains shared |
| WAN failover participation | `hosts/nixos/router/configuration.nix` and `hosts/nixos/router-backup/configuration.nix` via `enableWanHa` | Both nodes currently disable WAN HA. This keeps WAN locally managed on the primary and avoids HA-triggered WAN/networkd churn until the backup has a real standby WAN interface again |
| NIC stable names | `hosts/nixos/router/configuration.nix` (MAC-based) and `hosts/nixos/router-backup/configuration.nix` (PCI path-based) | Separate rules because the two machines use different matching strategies |
| DNS zone data (static hosts, aliases) | `hosts/nixos/router/dns-zone.nix` | Inline-imported by `configuration.nix`; edit here to manage DNS records |
| ulogd flow logging | `hosts/nixos/router/role.nix` (via nix-router-optimized) | Uses LOGEMU plugin (base `pkgs.ulogd`); JSON plugin requires overlay — not active by default |
| User overlay | `users/deepwatrcreatur/hosts/router/` and `users/deepwatrcreatur/hosts/router-backup/default.nix` | Applied via `primaryUserImports` in each den leaf |

---

## Where to land fixes

- **DNS / NTP shared capability**: `hosts/nixos/router/service-capability.nix`.
- **Primary hostname / domain defaults**: `hosts/nixos/router/networking.nix`.
- **Runtime single-owner LAN services**: `hosts/nixos/router/role.nix` via
  `services.router-ha.singleActiveUnits` and `/run/router-ha/role`.
- **Firewall / NAT / observability / VPN**: tune options provided by
  `nix-router-optimized` modules; the entry point is `den/aspects/router-router.nix`.
- **Caddy virtualHosts, ACME, DDNS**: `hosts/nixos/router/caddy.nix`.
- **DNS zone records**: `hosts/nixos/router/dns-zone.nix`.
- **Per-host role parameters** (device names, IPs, Grafana paths):
  `hosts/nixos/router*/configuration.nix` for the relevant host.
- **New shared router behaviour**: add a den aspect under `den/aspects/` and reference
  it in both `router` and `router-backup` `aspectsList` entries in
  `den/inventory/hosts.nix`.

## Current Consumer Failover Shape

The currently validated consumer failover split is:

- **VRRP / Keepalived owned**
  - LAN VIP ownership through `services.router-ha`
  - DDNS execution through `services.router-ha.singleActiveUnits`, currently
    using `inadyn.service` in this consumer tree
  - DHCP, UPnP, and IPv6 RA runtime ownership through the same
    `singleActiveUnits` boundary
- **Primary-only today**
  - public WAN ownership and public ingress, because WAN HA is disabled on both
    nodes until `router-backup` has a real WAN NIC and that failover path is
    revalidated
- **Shared on both nodes**
  - `services.router-ntp.enable = true` so Chrony stays available on the backup
  - Suricata and EveBox, which remain useful on standby without claiming
    single-owner semantics

This is the working reference shape today. It is still narrower than
"every important service follows VRRP automatically" because Chrony and other
shared observability services remain intentionally outside the single-owner
boundary, and WAN/public-ingress failover is deferred until the backup regains
real WAN hardware.

## Current HA Stage

The safest current interpretation of this pair is:

1. `router-backup` is a meaningful LAN-side standby and test target.
2. `router-backup` is not yet a full public-ingress substitute for `router`.
3. WAN/public-ingress failover should be re-enabled only after the backup has a
   real WAN NIC again and that path is validated separately.

## Current `activeOwner` Consumers

`router.failover.activeOwner` is now a legacy static hint, not the live
ownership switch for DDNS, DHCP, UPnP, or IPv6 RA. Those services follow the
runtime HA role file and `services.router-ha.singleActiveUnits` instead.

If future consumer code still uses `activeOwner`, that should be treated as an
explicit compatibility choice rather than the default HA mechanism.

The next consumer-side HA follow-up is tracked as
`nix-router-optimized/docs/work-items/75-consumer-active-owner-service-boundary-and-expansion.md`.
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
