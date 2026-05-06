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

## Active Ranking

1. [`35-ap-recovery-postmortem-gap.md`](./35-ap-recovery-postmortem-gap.md) - `ready`
2. [`37-router-backup-dhcp-regression-lab.md`](./37-router-backup-dhcp-regression-lab.md) - `ready`
3. [`38-router-dashboard-technitium-token-access.md`](./38-router-dashboard-technitium-token-access.md) - `ready`
4. [`41-optional-encrypted-dns-for-clients.md`](./41-optional-encrypted-dns-for-clients.md) - `ready`
5. [`42-apple-dns-privacy-compatibility.md`](./42-apple-dns-privacy-compatibility.md) - `ready`
6. [`44-kea-stork-dashboard.md`](./44-kea-stork-dashboard.md) - `ready`

## Recently Completed

- [`36-router-backup-ha-disable-profile.md`](./36-router-backup-ha-disable-profile.md) - `done`
- [`39-router-dashboard-kea-dhcp-cutover.md`](./39-router-dashboard-kea-dhcp-cutover.md) - `done`
- [`40-kea-state-ownership-hardening.md`](./40-kea-state-ownership-hardening.md) - `done`
- [`43-optional-extra-routed-networks.md`](./43-optional-extra-routed-networks.md) - `done`
