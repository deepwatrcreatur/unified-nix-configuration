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
- Delete the file when the work is fully merged and no longer needs tracking.
- If the work changes shape materially, update the file instead of creating
  drift in chat history only.
- Agents should also check whether the suggested branch/worktree already exists
  before claiming a `ready` item, but treat that only as a hint unless there is
  clear evidence of active ownership.

## Status Model

- `blocked`: do not start yet
- `ready`: can be started now
- `in-progress`: owned by an active branch / agent
- `done`: merged; file can be deleted

## Recommended Process

1. Keep this folder in git as the agent-facing source of truth.
2. Use GitHub issues only for items that need human discussion, prioritization,
   or longer-lived tracking across multiple PRs.
3. For narrow implementation tasks, the file in this folder is enough and is
   easier for agents to consume than issue threads.
4. For autonomous agent selection, use the rules in
   [`START-HERE.md`](./START-HERE.md).

## Ranking

Highest value first:

1. `01-router-recovery-invariants.md`
2. `02-stable-interface-matching.md`
3. `03-management-plane-independence.md`
4. `04-service-dependency-cleanup.md`
5. `05-router-health-model.md`
6. `06-boot-and-recovery-hardening.md`
7. `07-observability-and-flow-logging.md`
8. `08-vlans-and-vpn-policy-routing.md`

## Why This Structure

This repo is agent-heavy and branch-heavy. Small files work better than a
single long roadmap because they:

- reduce context loading for follow-up agents
- make ownership clearer
- map cleanly to one branch / one PR
- are easy to delete once merged

Keep GitHub issues for cross-cutting or discussion-heavy items. Keep concrete
implementation plans here.
