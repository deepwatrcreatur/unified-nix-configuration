# Router Firewall Roles And Interfaces

This router uses the upstream `services.router-firewall` module from
`nix-router-optimized`. That module is already role-aware:

- interface roles are defined in `services.router-optimizations.interfaces`
- `services.router-firewall` derives WAN / LAN / management interface lists from
  those roles when explicit lists are not set

## Interface Role Mapping

The router role wires interface roles as follows (see
`hosts/nixos/router/role.nix`):

- **wan**: `wan0` (role = `"wan"`)
- **lan**: `lan0` (role = `"lan"`)
- **management**: `ens18` (role = `"management"`)

`services.router-optimizations.interfaces` exposes these roles and devices, and
`services.router-firewall` consumes them automatically.

## Firewall Policy By Role

Given the defaults in `router-firewall.nix`, policy is structured by role:

- **WAN interfaces**
  - used as untrusted egress/ingress edges
  - `wanTcpPorts` / `wanUdpPorts` control which services are exposed on WAN
  - IPv4 masquerade is enabled by default for WAN egress

- **LAN + management interfaces (trusted)**
  - combined into `trustedInterfaces`
  - `trustedTcpPorts` / `trustedUdpPorts` control additional services on trusted
    segments
  - optional hairpin NAT (`hairpinNat.*`) uses routed LAN/management CIDRs by
    default

- **DNS/DHCP interfaces**
  - `dnsInterfaces` defaults to the same set of trusted interfaces
  - `dnsTcpPorts` / `dnsUdpPorts` expose DNS/DHCP-like ports toward LAN and
    management

## Router-Specific Configuration

In `hosts/nixos/router/role.nix` today we set:

```nix
services.router-firewall = {
  enable = true;
  trustedTcpPorts = [ 80 443 ];
  hairpinNat.enable = true;
  trustedUdpPorts = [ ];
  extraInputRules = ''
    iifname {"${lanDevice}"} tcp dport 5201 accept comment "iperf3 from LAN"
  '';
};
```

This keeps the default role-based mapping from `router-optimizations` while
explicitly:

- allowing HTTP/HTTPS from trusted interfaces
- enabling IPv4 hairpin NAT for routed LAN/management CIDRs
- exposing iperf3 on LAN for testing

## How To Extend Safely

When adding new firewall behavior:

- prefer adjusting role-aware options (`wanTcpPorts`, `wanUdpPorts`,
  `trustedTcpPorts`, `trustedUdpPorts`, `dnsInterfaces`) over hand-written
  nftables in `extra*Rules`
- keep WAN exposure explicit and minimal; use LAN/management for admin access
- update this doc and the router work-items queue if you introduce new
  role-specific behavior
