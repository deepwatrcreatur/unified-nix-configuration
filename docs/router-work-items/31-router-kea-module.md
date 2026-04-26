# 31 router-kea Module

Status: `done`
Suggested branch: `feat/router-kea-module`
Priority: `high`

## Goal

Implement `modules/router-kea.nix` in `nix-router-optimized` with `services.router-kea`
offering DHCPv4 (kea-dhcp4) and DDNS (kea-dhcp-ddns / D2) with TSIG-authenticated
RFC2136 updates to an authoritative DNS server (Technitium or any other).

## Why

The `router-dhcp` module uses systemd-networkd's built-in DHCP server, which has no
DNS registration path. Kea with D2 gives dynamic lease → DNS A-record registration
automatically, solving the "unknown host on LAN" problem.

## Scope

### `modules/router-kea.nix` in `nix-router-optimized`

```nix
options.services.router-kea = {
  enable = mkEnableOption "Kea DHCPv4 + DDNS for router LAN clients";

  dhcp4 = {
    interfaces    # listOf str — defaults to LAN ifaces from router-networking
    subnet        # str — CIDR (e.g. "10.10.0.0/16")
    poolRanges    # listOf { start; end; } — dynamic pool(s)
    defaultLeaseTimeSec  # default 86400
    maxLeaseTimeSec      # default 172800
    reservations  # listOf { hw-address; ip-address; hostname; }
    ddnsEnabled   # bool, default true — send DDNS updates
  };

  ddns = {
    enable         # bool — enables kea-dhcp-ddns service
    serverAddress  # str — DNS server to update, default "127.0.0.1"
    serverPort     # int, default 53
    tsigKeyFile    # path — runtime path to TSIG key secret (base64)
    tsigKeyName    # str — key name as registered in Technitium
    tsigAlgorithm  # str, default "HMAC-SHA256"
    forwardZone    # str — e.g. "deepwatercreature.com"
    reverseZone    # str — e.g. "10.10.in-addr.arpa" (optional)
  };
};
```

- Wire `services.kea.dhcp4` and `services.kea.dhcp-ddns`
- Auto-derive `interfaces` from `services.router-networking.routedInterfaces` (LAN role)
- Open UDP 67, 68 on LAN interfaces via `services.router-firewall.trustedUdpPorts`
- Disable `services.router-dhcp` assertion hint if both are enabled simultaneously

### Integration notes

- `tsigKeyFile` should point to `config.age.secrets.kea-ddns-tsig-key.path`
  (item 30); the module itself does not manage secrets, just reads the path
- Kea config files contain the raw TSIG key — use a `preStart` script or
  Kea's `secret-file` reference to avoid writing the key to the Nix store
- Register module as `router-kea` in `flake.nix` and include in
  `nixosModules.default`

## Non-Goals

- Technitium zone reconfiguration (item 32)
- Kea HA (future item)
- DHCPv6

## Validation

- `nix-instantiate --parse` on the new module
- `nix build .#checks.x86_64-linux.nixos-eval` passes in `nix-router-optimized`
- Test eval of a synthetic config enabling `services.router-kea` succeeds

## Dependencies

- Item 30 (TSIG key must exist to test end-to-end, but module can be written first)

## Outcome Notes (2026-04-24)

Module was implemented and substantially extended during the Kea/VRRP regression
incident (2026-04-23). The delivered module at
`nix-router-optimized/modules/router-kea.nix` covers everything in the original
scope plus:

- HA load-balancing mode with `libdhcp_ha.so` + `libdhcp_lease_cmds.so`
- Explicit `localAddress` option (with warning against 127.0.0.1)
- `outboundInterface` defaulting to `use-routing` when HA is enabled
- Build-time assertion rejecting address-qualified interface names
- PXE boot option advertisement
- Backup carrier guard (`ExecCondition` + carrier-sync service) for the standby node
- Runtime TSIG key injection via `ExecStartPre` (key never enters Nix store)

See `docs/kea-vrrp-regression-postmortem.md` for the full incident record and
guardrail rationale.
