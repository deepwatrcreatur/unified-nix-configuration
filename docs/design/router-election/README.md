# Router Election Design Notes

Status: `input` (design notes, not an implementation plan)

## Direction

Router function is moving away from a fixed primary plus a dedicated standby.
The plan is:

- routing becomes one aspect of a general NixOS host, not the whole host;
- a new bare-metal machine joins as a full NixOS system with routing as one of
  its aspects, alongside its other roles;
- an election decides which eligible host currently holds router function
  (gateway address, WAN, DHCP, DDNS, UPnP, IPv6 RA and the related services).

Today `router` is the only router host. Active HA is off (`enableHa = false`
in `hosts/nixos/router/configuration.nix`). The Kea HA peer settings in
`hosts/nixos/router/role.nix` still describe the removed `router-backup` VM
and are placeholders until the election design settles who the peers are.

## Where these notes came from

The files in [`2026-04-vrrp-pair/`](./2026-04-vrrp-pair/) were written in April
2026 for a `router` + `router-backup` pair using keepalived VRRP. They sat on
an unmerged branch (`feat/tooling-ssh-signing-modules`) and are kept here
unchanged apart from an archive banner. Paths inside them refer to where they
were originally written (see the path map below).

## What still applies

These lessons hold whatever the election mechanism turns out to be:

1. **Kea HA has its own state machine.** In the April incident, Kea in
   `READY`/`WAITING` read DHCP broadcasts and silently dropped them, which
   looked like a dead socket. Other traps were address-qualified interface
   names (`enp6s16/10.10.10.2`), a `127.0.0.1` peer URL and the missing
   `libdhcp_lease_cmds.so` hook
   ([post-mortem](./2026-04-vrrp-pair/kea-vrrp-regression-postmortem.md)).
   `nix-router-optimized`'s `router-kea` module now guards against the last
   three: it asserts against `/` in interface names, has an explicit
   `dhcp4.ha.localAddress` and loads the lease-commands hook with HA.
2. **Use one authority for who is active.** Kea HA, VRRP and an external
   election can each decide that a node is active. Running more than one of
   them unsynchronised is how the April pair ended up with DHCP disabled on
   the node clients were talking to. If the election is the authority, Kea is
   simpler as a single-active service started by the winner (see
   `nix-router-optimized/docs/router-dhcp-single-active.md`) than as a Kea HA
   pair that runs its own election alongside.
3. **Takeover order matters.** On promotion: commit replicated firewall state
   (`conntrackd -c`), then take the WAN (cloned MAC, interface up), then start
   application services such as Kea and Stork, which can start in any order. On
   demotion, do the reverse ([conntrackd decision](./2026-04-vrrp-pair/conntrackd-flowtable/DECISION.md)).
   These become the election's "won" and "lost" hooks.
4. **Stateful failover needs conntrackd, and it is not packaged as a
   service.** nixpkgs still has no `services.conntrackd` module, and the pinned
   `conntrack-tools` is still 1.4.8. Without the upstream OFFLOAD-bit fix,
   flows that the nftables flowtable has already offloaded can fail to inject
   after a resync. The router enables a flowtable, so a local patch is still
   needed. Validate with a long-lived, already-offloaded connection, not only
   short ones ([work item](./2026-04-vrrp-pair/conntrackd-firewall-state-sync.md)).
5. **Stork should use Kea's unix control socket and skip `kea-ctrl-agent`.**
   That avoids the port 8000 clash with the Kea HA listener
   ([note](./2026-04-vrrp-pair/kea-control-agent-stork-port.md)).
6. **Track deployed state separately from source state.** Half of the April
   incident was two nodes running different generations of a correct config.
   Any election rollout needs a check that every candidate runs the same
   generation before failover is tested.

Done since then: `nix-router-optimized` is a locked flake input and changes
reach hosts only through an explicit `nix flake update` (the April "input
pinning" work item).

## What needs rethinking for an election model

- **VRRP's role.** [ADR-001](./2026-04-vrrp-pair/ADR-001-vrrp-over-carp.md)
  chose keepalived because it is the standard Linux VRRP. With an election,
  decide whether VRRP only moves the gateway address on the election's
  instruction, or whether election and VRRP priority are the same thing.
  Avoid two independent decision-makers.
- **Shared hosts.** The winner keeps running its other services, so router
  units must start and stop cleanly without disturbing the rest of the host.
  Starting points: `services.router-ha.singleActiveUnits` and
  `nix-router-optimized/docs/router-ha-ownership.md`.
- **Network assumptions.** The April notes assume a dedicated management NIC
  (`192.168.100.0/24`) for sync and heartbeats, and that every candidate has a
  physical WAN path. Confirm both for each candidate host, or choose another
  sync path.
- **Stork server placement.** Either follow the election winner or run on a
  host that never holds router function ([note](./2026-04-vrrp-pair/stork-server-ha.md)).
- **Kea HA re-entry.** If Kea HA is still wanted, the evidence gate in
  `nix-router-optimized/docs/router-kea-ha-reentry-gate.md` applies.
  [kea-ha-pair-deployment.md](./2026-04-vrrp-pair/kea-ha-pair-deployment.md)
  is the old `router-backup` runbook and is useful only as a checklist.

## Files

| File | Originally | Still useful for |
|---|---|---|
| `ADR-001-vrrp-over-carp.md` | `docs/ADR-001-vrrp-over-carp.md` | Why VRRP over CARP on Linux; VRRP auth trade-offs |
| `kea-vrrp-regression-postmortem.md` | `docs/kea-vrrp-regression-postmortem.md` | Kea HA failure modes and guardrails |
| `kea-control-agent-stork-port.md` | `docs/router-work-items/35-kea-control-agent-stork-port.md` | Stork wiring without `kea-ctrl-agent` |
| `stork-server-ha.md` | `docs/router-work-items/36-stork-ha-vrrp-design.md` | Stork server placement |
| `kea-ha-pair-deployment.md` | `docs/router-work-items/37-kea-ha-pair-deployment.md` | Checklist only; targets the removed `router-backup` |
| `conntrackd-firewall-state-sync.md` | `docs/router-work-items/39-conntrackd-firewall-state-sync.md` | conntrackd design and validation |
| `conntrackd-flowtable/` | `docs/design/conntrackd-flowtable/` | Flowtable and conntrackd research, decision and takeover order |

Old references inside these files to `docs/router-spare-cutover.md`,
`standards/agentic-orchestration/` and `docs/incidents/` in this repo point to
files that no longer exist or were never committed. The incident record is in
`nix-router-optimized/docs/incidents/2026-04-23-dhcp-vrrp-regression/`.
