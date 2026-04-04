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

Highest value first:

1. `01-router-recovery-invariants.md`
2. `02-stable-interface-matching.md`
3. `04-service-dependency-cleanup.md`
4. `05-router-health-model.md`
5. `06-boot-and-recovery-hardening.md`
6. `07-observability-and-flow-logging.md`
7. `23-ulogd-plugin-mismatch-repair.md`
8. `24-ulogd-package-vs-design-alignment.md`
9. `08-vlans-and-vpn-policy-routing.md`
10. `09-kea-technitium-architecture.md`
11. `10-router-kea-module-roadmap.md`
12. `11-internal-admin-hostnames.md`
13. `12-vpn-module-hardening-and-tests.md`
14. `13-vyos-pattern-study.md`
15. `14-upstream-hotfix-pinning-policy.md`
16. `15-management-plane-smoke-validation.md`
