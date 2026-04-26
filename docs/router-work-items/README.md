# Router Work Items

Start here if you are assigning another agent:

- [`START-HERE.md`](./START-HERE.md)

This folder is the working queue for router follow-up after the current
stability/recovery fixes.

Use this instead of a single large planning doc when multiple agents will work
in parallel on separate worktrees.

## How To Use

- Treat each file in this folder as one PR-sized work stream.
- Prefer one agent per file/branch.
- Mark the file as `in-progress` in its header once an agent starts it.
- When work is fully merged, either delete the file or keep it briefly as
  `done` if it records useful outcome notes for follow-up agents.
- `done` items must not remain in the active ranking; archive or delete them
  once their notes are no longer useful.
- If the work changes shape materially, update the file instead of creating
  drift in chat history only.
- Agents should also check whether the suggested branch/worktree already exists
  before claiming a `ready` item, but treat that only as a hint unless there is
  clear evidence of active ownership.

## Status Model

- `blocked`: do not start yet
- `ready`: can be started now
- `in-progress`: owned by an active branch / agent
- `done`: merged; may remain briefly for outcome notes, but should be archived
  or deleted and removed from the active ranking

## Recommended Process

1. Keep this folder in git as the agent-facing source of truth.
2. Use GitHub issues only for items that need human discussion, prioritization,
   or longer-lived tracking across multiple PRs.
3. For narrow implementation tasks, the file in this folder is enough and is
   easier for agents to consume than issue threads.
4. For autonomous agent selection, use the rules in
   [`START-HERE.md`](./START-HERE.md).

## Ranking

Items marked `done` are kept briefly for outcome notes then archived.

### Active Queue

1. [`37-kea-ha-pair-deployment.md`](./37-kea-ha-pair-deployment.md) - `ready` ⚠️ closes open incident
2. [`33-router-iventoy-runtime-repair.md`](./33-router-iventoy-runtime-repair.md) - `ready`
3. [`34-router-miniupnpd-interface-repair.md`](./34-router-miniupnpd-interface-repair.md) - `ready`
4. [`29-router-cutover-validation-hardening.md`](./29-router-cutover-validation-hardening.md) - `ready`
5. [`27-router-pxe-boot-module-plumbing.md`](./27-router-pxe-boot-module-plumbing.md) - `ready`
6. [`30-kea-tsig-key-provisioning.md`](./30-kea-tsig-key-provisioning.md) - `ready`
7. [`32-kea-dhcp-cutover.md`](./32-kea-dhcp-cutover.md) - `blocked` (needs 30; also recommended after 37)
8. [`35-kea-control-agent-stork-port.md`](./35-kea-control-agent-stork-port.md) - `ready`
9. [`36-stork-ha-vrrp-design.md`](./36-stork-ha-vrrp-design.md) - `ready` (needs 35 first)
10. [`39-conntrackd-firewall-state-sync.md`](./39-conntrackd-firewall-state-sync.md) - `ready` (design closed — see `docs/design/conntrackd-flowtable/DECISION.md`)
11. [`38-nix-router-optimized-input-pinning.md`](./38-nix-router-optimized-input-pinning.md) - `ready` (recommended after 37)

### Recently Done

- [`31-router-kea-module.md`](./31-router-kea-module.md) - `done` (implemented + extended during 2026-04-23 incident)
- [`29-router-caddy-source-drift-repair.md`](./29-router-caddy-source-drift-repair.md) - `done`
- [`28-router-dashboard-review-hardening.md`](./28-router-dashboard-review-hardening.md) - `done`
- [`28-dhcp-provider-pluggable-observability.md`](./28-dhcp-provider-pluggable-observability.md) - `done`
- [`27-router-post-cutover-validation.md`](./27-router-post-cutover-validation.md) - `done`
- [`26-router-dashboard-runtime-repair.md`](./26-router-dashboard-runtime-repair.md) - `done`
- [`25-technitium-dhcp-sync-hardening.md`](./25-technitium-dhcp-sync-hardening.md) - `done`
