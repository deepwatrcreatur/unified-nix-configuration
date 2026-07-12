# Router Spare Cutover

`router` and `router-backup` are separate management nodes. The current
production shape is intentionally non-HA: `router` is the only active router,
and `router-backup` is a cold/manual spare.

High availability is intentionally deferred for now. Treat the active HA design
as future work to revisit only after more pressing router needs are settled and
the backup has real standby WAN hardware again.

For the active primary's post-reboot acceptance checks, use
[`router-reboot-validation.md`](./router-reboot-validation.md).

## Management

- `router` SSHes to the dedicated management interface at `192.168.100.100`
- `router-backup` SSHes to the dedicated management interface at `192.168.100.99`
- both remain reachable on the out-of-band virtio network even when only one of
  them is connected to the production WAN/LAN NICs

## Production Identity

- `router` owns the production LAN identity `10.10.10.1/16`
- `router-backup` keeps its own local standby LAN address for lab work, but it
  does not claim the production router identity automatically
- public WAN/public-ingress failover is currently disabled in HA config. WAN
  stays locally managed on `router` until `router-backup` has a real WAN NIC
  and the failover path is validated separately

## Promotion

To recover with `router-backup` after a failure or bad rebuild:

1. Confirm `router` is out of service or should no longer be the active node.
2. Verify `router-backup` still has management reachability.
3. Promote it manually only after checking which client-path services you intend
   to bring up there.
4. Verify the production LAN identity is present on the replacement node before
   expecting clients to recover.
5. Expect LAN recovery only; WAN/public-ingress failover is intentionally out
   of scope in the current stage.

## Deferred HA TODO

When you eventually return to HA work, keep this order:

1. preserve the current single-active-router production model until the new HA
   slice is fully validated
2. test any new HA ownership or VRRP logic on `router-backup` first
3. prefer reboot-based primary validation over live `nixos-rebuild switch`
   cutovers
4. do not re-enable WAN/public failover until `router-backup` has a real WAN
   path again

### Current config note

- `router.failover.activeOwner` is now only a legacy static hint for the
  preferred node, not the live service-promotion switch.
- The current production tree does not use VRRP-owned runtime LAN services.
- `router` owns:
  - `inadyn.service`
  - `kea-dhcp4-server.service`
  - `kea-dhcp-ddns-server.service`
  - `miniupnpd.service`
  - IPv6 RA emission on the production LAN
- `router-backup` keeps those services disabled until a deliberate recovery or
  later HA redesign reintroduces them safely.
- `services.router-ntp.enable = true` on both nodes. Chrony is intentionally
  shared rather than single-owner in the current deployment.
- `services.router-network-security` is currently disabled on both nodes in the
  simplified production shape. Suricata/EveBox were removed from the active
  boot path while primary reboot stability was being restored.
- WAN HA is currently disabled on both nodes. `router-backup` has no attached
  standby WAN device, and the current router-ha WAN hooks are too disruptive on
  the primary because they restart `systemd-networkd` during promotion.
- This means the current split is:
  - client-path LAN services and public ingress: primary-owned
  - Chrony and some observability: shared on both nodes
  - backup promotion: manual, not automatic

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
- WAN ownership beyond the current primary-local boundary

### Standby Checklist

After enabling clustering, still verify the standby router manually:

- Technitium on `router-backup` shows healthy cluster sync
- the `LAN` DHCP scope exists on `router-backup`
- the dynamic pool matches the intended standby settings
- only the active router is expected to own production client-path services

## Standby / Dev Router Behavior

When a router is used as a spare or dev box:

- the management IP on the virtio interface stays reachable even with WAN/LAN unplugged
- the production LAN identity stays on `router` unless you deliberately
  reassign it during a manual recovery
- LAN/WAN-dependent checks are expected to show degraded or failed until cables are reattached
