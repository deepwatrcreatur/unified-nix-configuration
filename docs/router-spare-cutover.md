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
- VRRP/Keepalived decides which node currently owns the VIP and WAN-side active
  role
- both nodes can stay cabled to the production LAN when the HA pair is healthy;
  the safety rule is that only one node should own the active role at a time

## Promotion

To recover with `router-backup` after a failure or bad rebuild:

1. Confirm `router` is out of service or should no longer be the active node.
2. Verify `router-backup` still has management reachability.
3. Confirm VRRP/WAN ownership, not just service state:
   - `/run/router-ha/role`
   - `systemctl status keepalived`
4. Verify the production identity is present on the promoted node:
   - the LAN VIP answers
   - WAN ownership and public ingress behave as expected
5. Verify client-facing services that are supposed to move or remain shared.

### Current config note

- `router.failover.activeOwner` is the consumer-tree switch for single-owner
  public identity. It currently defaults to `true` on `router` and `false` on
  `router-backup`.
- Today that switch gates:
  - `kea-dhcp4-server.service`
  - `kea-dhcp-ddns-server.service`
  - `services.router-upnp.enable`
  so only the configured active owner answers LAN DHCP or advertises
  UPnP/NAT-PMP mappings.
- DDNS execution no longer hangs off `activeOwner` directly. The current
  consumer tree hands `inadyn.service` to
  `services.router-ha.singleActiveUnits`, and adds any corresponding inadyn
  timer unit only when the evaluated system exposes that unit name, so DDNS
  follows VRRP promotion without assuming a timer name that may not exist.
- `services.router-ntp.enable = true` on both nodes. Chrony is intentionally
  shared rather than single-owner in the current deployment.
- This means the current failover split is:
  - VRRP/WAN/DDNS: promotion-aware
  - Chrony and some observability: shared on both nodes
  - DHCP and UPnP: still explicit single-owner policy in the consumer config

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
