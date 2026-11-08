# Router Source of Truth

This document maps where each router concern lives so agents know which file
to edit first and which files are legacy mirrors or wiring glue.

`router` is a `mode = "aspect"` entry in `den/inventory/hosts.nix`. Its output
flows through `mkInventoryOutputs`. It is the only router host in this repo;
the former `router-backup` VM spare was removed in favour of a separate
bare-metal machine.

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

---

## Per-concern source of truth

| Concern | Active file | Notes |
|---------|-------------|-------|
| Hardware config (router) | `hosts/nixos/router/hardware-configuration.nix` | Generated; never edit manually |
| Hostname | `hosts/nixos/router/networking.nix` | |
| Shared DNS/NTP capability | `hosts/nixos/router/service-capability.nix` | Shared router service capability |
| NAT policy | `hosts/nixos/router/service-capability.nix` | `networking.nat.enable = false`; nftables handles NAT in role.nix |
| Disk layout (router) | `hosts/nixos/router/disko.nix` | Hardware-adjacent; keep separate |
| Caddy / ingress | `hosts/nixos/router/caddy.nix` | Public ingress is served by `router`; WAN HA is disabled |
| Router role (networking, firewall, DNS, observability, VPN) | `den/aspects/router-router.nix` + upstream `nix-router-optimized` modules | The den aspect selects which upstream modules to import |
| Host-specific role args (WAN/LAN devices, IPs, Grafana paths) | `hosts/nixos/router/configuration.nix` | Calls `role.nix` as a function with per-host arguments |
| Runtime LAN service ownership | `hosts/nixos/router/role.nix` via `enableHa` and `ownLanServices` | The current production shape is non-HA: `router` owns DDNS, DHCP, UPnP, and IPv6 RA directly |
| WAN failover participation | `hosts/nixos/router/configuration.nix` via `enableWanHa` | Disabled; WAN is locally managed on `router` |
| NIC stable names | `hosts/nixos/router/configuration.nix` (MAC-based) | |
| DNS zone data (static hosts, aliases) | `hosts/nixos/router/dns-zone.nix` | Inline-imported by `configuration.nix`; edit here to manage DNS records |
| ulogd flow logging | `hosts/nixos/router/role.nix` (via nix-router-optimized) | Uses LOGEMU plugin (base `pkgs.ulogd`); JSON plugin requires overlay — not active by default |
| User overlay | `users/deepwatrcreatur/hosts/router/` | Applied via `primaryUserImports` in the den leaf |

---

## Where to land fixes

- **DNS / NTP shared capability**: `hosts/nixos/router/service-capability.nix`.
- **Primary hostname / domain defaults**: `hosts/nixos/router/networking.nix`.
- **Runtime LAN service ownership**: `hosts/nixos/router/role.nix` via
  `enableHa` and `ownLanServices`.
- **Firewall / NAT / observability / VPN**: tune options provided by
  `nix-router-optimized` modules; the entry point is `den/aspects/router-router.nix`.
- **Caddy virtualHosts, ACME, DDNS**: `hosts/nixos/router/caddy.nix`.
- **DNS zone records**: `hosts/nixos/router/dns-zone.nix`.
- **Per-host role parameters** (device names, IPs, Grafana paths):
  `hosts/nixos/router/configuration.nix`.
- **New shared router behaviour**: add a den aspect under `den/aspects/` and reference
  it in the `router` `aspectsList` entry in `den/inventory/hosts.nix`.

## Current Consumer Shape

The currently validated consumer shape is intentionally simpler than active HA:

- **Primary-owned today**
  - LAN gateway identity and client-path services on `router`
  - DDNS, DHCP, UPnP, and IPv6 RA, all owned directly by `router`
  - public WAN ownership and public ingress (WAN HA is disabled)
- **Temporarily disabled in the current simplified mode**
  - `services.router-network-security`
  - Suricata / EveBox
  - These are intentionally out of the active boot path while the primary
    reboot path is being stabilized. Reintroduce them later as a separate,
    reboot-tested slice rather than bundling them with router ownership work.

This is the working reference shape today. VRRP/Keepalived is no longer part of
the live production path, because the current HA hooks are still too disruptive
for safe primary reboots.

## Current Recovery Stage

`router` is the only production router managed by this repo. Standby router
functionality is planned on a separate bare-metal machine; until that is added,
there is no failover peer.

For the current primary-router post-reboot checks, use
[`router-reboot-validation.md`](./router-reboot-validation.md).

## Deferred Follow-Up

High availability is now an intentional future follow-up, not an active
deployment goal. Before revisiting it, the next implementation should assume:

1. the current supported production shape is `router` as the only router
2. any future HA retry must be validated on the standby first, then staged for
   reboot-based primary testing instead of live `switch` cutovers
3. the HA peer settings in `hosts/nixos/router/role.nix` (`peerAddress`,
   `peerName`, `keaSync.peerAddress`) still describe the removed spare and must
   be updated for the new standby before HA is enabled

## Current `activeOwner` Consumers

`router.failover.activeOwner` is now a legacy static hint, not the live
ownership switch for DDNS, DHCP, UPnP, or IPv6 RA. In the current production
shape those services are simply enabled on `router`.

If future consumer code still uses `activeOwner`, that should be treated as an
explicit compatibility choice rather than the default HA mechanism.

The next consumer-side HA follow-up is tracked as
`nix-router-optimized/docs/work-items/75-consumer-active-owner-service-boundary-and-expansion.md`.
- **Hardware**: regenerate `hardware-configuration.nix` on the target machine with
  `nixos-generate-config`; never edit the generated file.

---

## Legacy files still active (migration status)

All `extraImports` in the den leaf are legacy files not yet represented as den
aspects. The table below summarises migration readiness.

| File | Reason still separate | Migration candidate? |
|------|-----------------------|---------------------|
| `hosts/nixos/router/hardware-configuration.nix` | Generated hardware config | No — keep separate always |
| `hosts/nixos/router/networking.nix` | Reads `config.router.topology` at module eval time; cannot be a static den aspect without topology-aware aspect support | Yes, once topology config moves to den |
| `hosts/nixos/router/caddy.nix` | 194 lines; large host-local file | No urgent need; keep separate |
| `hosts/nixos/router/disko.nix` | Disk layout; hardware-adjacent | No — keep separate always |
| `hosts/nixos/router/configuration.nix` | Wires `role.nix` with host-specific args; needs den aspect function-call pattern | Yes — long-term goal once role.nix API stabilises |
