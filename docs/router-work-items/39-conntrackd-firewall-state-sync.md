# 39 conntrackd Firewall State Sync

Status: `ready`
Suggested branch: `feat/router-conntrackd-state-sync`
Priority: `medium`

## Goal

Add `conntrackd` to both routers so that firewall connection state is
replicated in real time between the VRRP pair. When keepalived triggers a
failover, the new primary already has a full conntrack table and existing TCP
connections survive without reset.

## Why

The current `router-ha.nix` implements gateway failover (VIP floating via
keepalived) but not stateful failover. The backup router starts with an empty
conntrack table after promotion. Every established connection — SSH sessions,
active downloads, streaming — stalls until the client retries or the connection
times out.

OPNsense solves this with `pfsync` (BSD-only). The Linux equivalent is
`conntrackd`, which synchronises the kernel's netfilter conntrack table between
peers over a dedicated UDP channel.

## Design

### Sync transport

Use the **management plane** (`192.168.100.x`) as the sync interface, not the
LAN. This:
- avoids consuming LAN bandwidth with conntrack replication traffic
- survives LAN disruption (which is a plausible failure scenario)
- matches how Kea HA was originally wired before the LAN-plane migration

### Mode

Use `FTFW` (Fault Tolerant Finite Window) mode. This is the recommended mode
for active/backup pairs: it sends a bulk sync on startup and then delta-syncs
new/updated entries in real time.

### Integration with keepalived

`conntrackd` needs to be notified when keepalived transitions roles so it can
trigger a bulk-sync commit on promotion. keepalived's notify scripts handle
this:

```
notify_master: conntrackd -c   # commit external cache to kernel
notify_backup: conntrackd -f   # flush internal cache, start fresh as backup
notify_fault:  conntrackd -f
```

These are added to the `router-ha.nix` module alongside the existing WAN
interface notify scripts.

## Implementation

### In `nix-router-optimized/modules/router-ha.nix`

Add a new option block:

```nix
stateSync = {
  enable = mkEnableOption "conntrackd firewall state synchronisation";
  syncInterface = mkOption {
    type = types.str;
    example = "ens17";
    description = "Interface used for conntrack sync traffic (management plane recommended).";
  };
  peerAddress = mkOption {
    type = types.str;
    example = "192.168.100.99";
    description = "Management-plane IP of the peer router.";
  };
  localAddress = mkOption {
    type = types.str;
    example = "192.168.100.100";
    description = "Management-plane IP of this router.";
  };
};
```

Wire `services.conntrackd` in FTFW mode when `stateSync.enable = true`.

Add conntrackd notify calls to the keepalived master/backup/fault scripts
alongside the existing WAN management.

### Firewall

Open the conntrackd sync port (UDP 3780 by default) on the management-plane
interface between the two routers. This does not need to be open on LAN or WAN.

### In `unified-nix-configuration` (consumer side)

Enable on both routers:

```nix
services.router-ha.stateSync = {
  enable = true;
  syncInterface = "ens17";          # management plane NIC
  peerAddress   = "192.168.100.99"; # router-backup mgmt IP
  localAddress  = "192.168.100.100";
};
```

## Validation

- On the active primary: `conntrackd -s` shows entries being replicated
- On the backup: `conntrackd -s` shows entries being received
- Trigger a manual failover (`systemctl stop keepalived` on primary)
- An active SSH session or `ping` through the router survives the failover
  without reset
- `conntrack -L` on the new primary shows the pre-failover entries

## Limitations

- Short-lived UDP flows (DNS, NTP) will not survive failover regardless —
  conntrack entries may not exist yet at the moment of transition. This is
  acceptable; DNS clients retry automatically.
- Extremely high-throughput connections may create sync lag. At homelab scale
  this is not a concern.
- conntrackd does not sync NAT helper state (FTP, SIP ALG). These connections
  reset on failover. At homelab scale this is acceptable.

## Implementation Constraints (from design discussion)

See `docs/design/conntrackd-flowtable/DECISION.md` for full rationale.

**conntrack-tools patch — blocking prerequisite:** nixpkgs 25.11 ships
`conntrack-tools` 1.4.8. This version has a `-EBUSY` bug: when `conntrackd -c`
attempts to inject entries that carry the `IPS_OFFLOAD` bit (sourced from the
bulk dump/resync path), the kernel rejects the write via
`nf_ct_change_status_common`. Offloaded flows fail to inject and do not survive
failover at 1.4.8.

No confirmed upstream release contains the fix. Latest tag is 1.4.9; its
changelog does not include the OFFLOAD-bit masking change.

The implementation must apply a **local derivation patch** to the 1.4.8
package. The patch masks `IPS_OFFLOAD` (0x4000) and `IPS_HW_OFFLOAD` (0x8000)
from the status field in `src/netlink.c` before writing to the kernel:
- Function: `nl_create_conntrack` (approx. line 236)
- Function: `nl_update_conntrack` (approx. line 290)
- Change: `status &= ~(IPS_OFFLOAD | IPS_HW_OFFLOAD);` before the status
  attribute is serialised.

Note: `StartupResync` defaults to disabled in FTFW mode, so the poisoned-cache
window is bounded to netlink overrun recovery and explicit resyncs — not every
restart. Do not enable `StartupResync` in the generated config unless there is
a specific reason.

**Flowtable interaction:** Standard FTFW sync is sufficient once the version
constraint above is satisfied. Offloaded flows survive failover via the
established-state slow-path fallback — the OFFLOAD bit is stripped before
injection (1.5.0+), the entry lands in the kernel as ESTABLISHED, and
`ct state established accept` handles the brief re-entry window. No special
conntrackd configuration knobs needed.

**No NixOS module:** `services.conntrackd` does not exist in nixpkgs.
`router-ha.nix` must generate `conntrackd.conf` and define the systemd unit
directly. Expose at minimum: sync interface, local address, peer address, FTFW
mode, commit timeout.

**Failover sequence in notify_master:**
1. `conntrackd -c` (commit cache to kernel — must be first)
2. WAN MAC clone + interface up
3. Kea + Stork start (parallel, order-independent)

**Validation must include an already-offloaded flow.** A test that only checks
short-lived connections does not exercise the flowtable re-entry path. Use a
long-lived `iperf3` or `scp` session that has been running long enough to be
offloaded, then trigger failover while it is active.

## Dependencies

- Design discussion closed — `docs/design/conntrackd-flowtable/DECISION.md`
- Item 37 (HA pair deployment) — conntrackd is only useful once the VRRP pair
  is in a verified stable state
- Existing `router-ha.nix` notify script pattern — this item extends it
