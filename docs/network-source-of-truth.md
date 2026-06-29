# Network Source Of Truth

This repo uses several different systems for network-facing behavior. They do
not all own the same thing.

## Internal Hostnames

Technitium is the source of truth for internal DNS behavior on the LAN.

- DHCP clients register there
- DHCP reservations are synced there from this repo
- internal host lookups should be thought of as Technitium/DHCP state

For normal homelab machine discovery, prefer Technitium-hosted names over
public DNS assumptions.

## Public Ingress

[`lib/hosts.nix`](../lib/hosts.nix) is the source of truth for public ingress
inventory.

- `router.publicIngressServices`: names that should be served by router/Caddy
- `router.ddnsServices`: public names that Cloudflare dynamic DNS should track

These are internet-facing service names, not a list of all homelab machines.

## Reverse Proxy

[`hosts/nixos/router/caddy.nix`](../hosts/nixos/router/caddy.nix) is the source
of truth for how public ingress names are terminated and proxied.

Inventory checks enforce that router public ingress inventory and Caddy virtual
hosts stay aligned.

## Internal DNS Zone Records

[`hosts/nixos/router/dns-zone.nix`](../hosts/nixos/router/dns-zone.nix)
generates LAN DNS records from [`lib/hosts.nix`](../lib/hosts.nix).

This is for static machine names and aliases that should exist in the local
zone, not for WAN IP publication.

## Tailscale

Tailscale is a separate access mechanism.

- use it for private remote access to key machines
- do not treat it as a replacement for LAN DNS
- do not treat public Cloudflare/Caddy ingress as the default way to reach
  internal machines

## DHCP Scope

The base Technitium DHCP scope and dynamic pool are intentionally UI-managed
for bootstrap safety right now.

- the router should still be able to hand out working leases on a fresh bring-up
- the repo currently manages reservations and related options, not the base
  dynamic range

If `router` and `router-backup` are both kept online on the management network,
Technitium clustering can be used to keep DNS/admin configuration aligned
between them. In the current consumer boundary, that also means LAN-facing DNS
service is intentionally treated as a shared capability on both routers rather
than another `router.failover.activeOwner` surface.

This does not currently extend to DHCP scopes or lease state, so the standby
router still needs its DHCP scope checked separately in the web UI.

If that changes later, the preferred path is a reliable blank-state bootstrap
flow, not a best-effort day-2 sync only.
