# Router Spare Cutover

`router` and `router-backup` are separate management nodes, but they share the
same production router identity.

## Management

- `router` SSHes to the dedicated management interface at `192.168.100.100`
- `router-backup` SSHes to the dedicated management interface at `192.168.100.99`
- both remain reachable on the out-of-band virtio network even when only one of
  them is connected to the production WAN/LAN NICs

## Production Identity

- both router hosts are configured with the same production LAN address:
  `10.10.10.1/16`
- this is safe only because only one machine should be physically connected to
  the production WAN/LAN ports at a time
- do not leave both machines cabled to the production LAN while both claim
  `10.10.10.1`

## Promotion

To promote `router-backup` after a failure or bad rebuild:

1. Confirm `router` is out of service.
2. Power down or isolate `router` from the production WAN/LAN NICs.
3. Move the WAN cable to `router-backup`.
4. Move the LAN cable to `router-backup`.
5. Verify clients can reach `10.10.10.1`, resolve DNS, and reach the internet.

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
- default-gateway failover
- WAN ownership

### Standby Checklist

After enabling clustering, still verify the standby router manually:

- Technitium on `router-backup` shows healthy cluster sync
- the `LAN` DHCP scope exists on `router-backup`
- the dynamic pool matches the intended standby settings
- only the active router is connected to production WAN/LAN
