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

1. [`25-technitium-dhcp-sync-hardening.md`](./25-technitium-dhcp-sync-hardening.md) - `done`
2. [`26-router-dashboard-runtime-repair.md`](./26-router-dashboard-runtime-repair.md) - `in-progress`
3. [`27-router-post-cutover-validation.md`](./27-router-post-cutover-validation.md) - `done`
4. [`28-dhcp-provider-pluggable-observability.md`](./28-dhcp-provider-pluggable-observability.md) - `ready`
