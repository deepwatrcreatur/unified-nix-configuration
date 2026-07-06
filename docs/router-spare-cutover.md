# Router Spare Cutover

`router` and `router-backup` are separate management nodes that now participate
in a shared VRRP-based router identity.

## Management

- `router` SSHes to the dedicated management interface at `192.168.100.100`
- `router-backup` SSHes to the dedicated management interface at `192.168.100.99`
- both remain reachable on the out-of-band virtio network even when only one of
  them is connected to the production WAN/LAN NICs

## Production Identity

- the shared LAN VIP is `10.10.10.1/16`
- `router` and `router-backup` each also keep their own stable node address on
  the LAN
- VRRP/Keepalived decides which node currently owns the LAN VIP
- both nodes can stay cabled to the production LAN when the HA pair is healthy;
  the safety rule is that only one node should own the active role at a time
- public WAN/public-ingress failover is currently primary-only because
  `router-backup` does not have a real WAN NIC attached

## Promotion

To recover with `router-backup` after a failure or bad rebuild:

1. Confirm `router` is out of service or should no longer be the active node.
2. Verify `router-backup` still has management reachability.
3. Confirm VRRP role, not just service state:
   - `/run/router-ha/role`
   - `systemctl status keepalived`
4. Verify the production identity is present on the promoted node:
   - the LAN VIP answers
   - if the backup node has no WAN NIC, expect LAN recovery only rather than
     public-ingress failover
5. Verify client-facing services that are supposed to move or remain shared.

### Current config note

- `router.failover.activeOwner` is now only a legacy static hint for the
  preferred node, not the live service-promotion switch.
- DDNS execution no longer hangs off `activeOwner` directly. The current
  consumer tree hands `inadyn.service` to
  `services.router-ha.singleActiveUnits`, so DDNS follows VRRP promotion via
  the active node without depending on a separate systemd timer unit.
- The same runtime HA boundary now owns:
  - `kea-dhcp4-server.service`
  - `kea-dhcp-ddns-server.service`
  - `miniupnpd.service`
  - `router-ipv6-ra-owner.service`
  so the promoted node answers LAN DHCP, advertises UPnP/NAT-PMP mappings, and
  emits IPv6 RAs without needing a separate static owner flag.
- `services.router-ntp.enable = true` on both nodes. Chrony is intentionally
  shared rather than single-owner in the current deployment.
- `router-backup` currently has no attached WAN device, so `enableWanHa = false`
  there. That keeps LAN-side standby behavior available without letting
  Keepalived or HA hooks manipulate a nonexistent `ens27`.
- This means the current failover split is:
  - LAN VIP/DDNS/DHCP/UPnP/IPv6 RA: promotion-aware
  - public WAN/public ingress: primary-only until the backup regains a real WAN NIC
  - Chrony and some observability: shared on both nodes

## Technitium

- Technitium clustering can help keep DNS/admin configuration aligned between
  the two routers
- DHCP scopes are still not clustered in the released Technitium version, so
  the standby router's dynamic pool must still be checked in the web UI
- static reservations remain declarative in git

### Recommended Setup

Use Technitium clustering only for DNS/admin-state sync between `router` and
`router-backup`.

- make `router` the primary Technitium node
- join `router-backup` as a secondary node
- keep both nodes reachable over the management network
- do not treat clustering as DHCP failover

### What Clustering Helps With

- DNS zones and records managed in Technitium
- admin/application configuration inside Technitium
- reducing drift between the primary and spare router

### What It Does Not Solve

- DHCP scope replication
- DHCP lease-state failover
- automatic DHCP ownership transfer
- WAN ownership beyond what VRRP/Keepalived is already configured to do

### Standby Checklist

After enabling clustering, still verify the standby router manually:

- Technitium on `router-backup` shows healthy cluster sync
- the `LAN` DHCP scope exists on `router-backup`
- the dynamic pool matches the intended standby settings
- only the active router is connected to production WAN/LAN

## Standby / Dev Router Behavior

When a router is used as a spare or dev box:

- the management IP on the virtio interface stays reachable even with WAN/LAN unplugged
- the shared production identity is the VRRP VIP plus per-node LAN addresses,
  not two identical static host addresses
- LAN/WAN-dependent checks are expected to show degraded or failed until cables are reattached
