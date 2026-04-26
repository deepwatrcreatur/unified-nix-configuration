# Design Brief: conntrackd + nftables Flowtable Interaction

**Status:** OPEN — awaiting positions from agents before implementation proceeds
**Feeds into:** Work item 39 (`39-conntrackd-firewall-state-sync.md`)
**Owner:** Calder (human)

---

## Context

We want to add `conntrackd` firewall state sync to the VRRP pair so that
existing TCP connections survive router failover (work item 39). The
implementation plan in that item assumed standard conntrack sync via FTFW mode.

However, `nix-router-optimized/modules/router-firewall.nix` has a real nftables
flowtable (`services.router-firewall.flowtable.enable`). When active, it offloads
established connections to an ingress-priority fast path. Offloaded connections
are still represented as conntrack entries, but they carry `CT_STATUS_OFFLOADED`
and subsequent packets bypass the normal netfilter hook path.

This creates at least one non-obvious interaction with conntrackd that must be
understood before implementation starts.

---

## Questions That Need Answered

### Q1 — Flowtable/conntrackd interaction (blocking)

Do conntrackd's NETLINK_NETFILTER listeners receive update events for
`CT_STATUS_OFFLOADED` conntrack entries? Specifically:

- When a connection is offloaded to the flowtable, does conntrackd see a
  conntrack update event? Or does the offload transition happen below the
  NETLINK layer?
- If the entry IS synced to the backup, and failover occurs, does the backup's
  forward chain correctly accept traffic for the restored entry (via
  `ct state established accept`) before the flowtable re-offloads it?
- Is there a conntrackd configuration knob (`Cache`, `IgnoreTrafficFor`, or
  similar) that controls whether OFFLOAD entries are replicated?

**Why this matters:** If OFFLOAD entries are not synced, then the connections
most likely to survive failover (long-running, high-throughput, already
offloaded) are exactly the ones that won't. The work item's validation checklist
would pass with short-lived test connections while silently failing for the
real-world case.

### Q2 — NixOS `services.conntrackd` module surface (blocking)

What does the NixOS `services.conntrackd` module actually expose? Specifically:

- Does it support FTFW mode declaratively, or does it require a raw
  `configFile` passthrough?
- Does it expose the sync interface, peer address, and multicast/unicast mode
  as typed options, or as opaque string blobs?
- What version of conntrackd does current nixpkgs provide?

This determines whether `router-ha.nix` should wrap the NixOS module cleanly or
bypass it with a generated config file.

### Q3 — Failover sequencing (design input, not blocking)

When keepalived transitions a node to MASTER, the following things now need to
happen in a defined order:

1. conntrackd commits external cache to kernel (`conntrackd -c`)
2. Kea DHCP takes over (via the carrier-sync service or direct HA state)
3. WAN MAC clone + interface up (existing notify_master script)
4. Stork server starts (planned in item 36)

What is the correct sequence? Are there ordering dependencies between these
steps? Can any run in parallel?

The current `router-ha.nix` `notify_master` script does only (3). If (1) needs
to run before (3) to avoid connection resets during the MAC-clone window, the
script ordering matters.

---

## How To Contribute a Position

Write a signed position to `ACTIVE_DISCUSSION.md` in this directory using the
format from `standards/agentic-orchestration/MODEL.md`. Address one or more of
the three questions above with direct evidence (source code references, kernel
docs, version checks, or live test results). Do not write implementation code
until the blocking questions (Q1, Q2) have a consensus position.

When Q1 and Q2 have positions, the IC (Calder) will record the decision in
`DECISION.md` and update work item 39 with implementation constraints before
releasing it to an implementation agent.
