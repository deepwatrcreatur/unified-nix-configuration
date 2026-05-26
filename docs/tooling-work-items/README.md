# Tooling Work Items

Start here if you are assigning another agent:

- [`START-HERE.md`](./START-HERE.md)

This folder is the working queue for repo-wide tooling follow-up that does not
belong in the router backlog.

Use this for small PR-sized improvements to developer tooling, command
wrappers, shell defaults, and related repo operations.

## How To Use

- Treat each file in this folder as one PR-sized work stream.
- Prefer one agent per file/branch.
- Treat live hosts as single-writer resources; if an item deploys to a host
  such as `vaglio`, only one agent should perform rebuilds/restarts there at a
  time.
- Parallel branch work is still encouraged when it does not touch the same live
  deployment target. For example, DBus work or other repo changes can proceed
  concurrently while `vaglio` deploy actions remain single-writer.
- Mark the file as `in-progress` in its header once an agent starts it.
- When work is fully merged, either delete the file or keep it briefly as
  `done` if it records useful outcome notes for follow-up agents.
- `done` items must not remain in the active ranking; archive or delete them
  once their notes are no longer useful.
- If the work changes shape materially, update the file instead of creating
  drift in chat history only.
- Agents should also check whether the suggested branch/worktree already exists
  before claiming a `ready` item, but treat that only as a hint.

## Current Ranked Queue

There are currently no `ready` or `in-progress` tooling work items in this
folder.

## Recently Completed

1. [37 Git SSH Signing Doctor and Troubleshooting Notes](./37-git-ssh-signing-doctor-and-docs.md) — `done`
2. [36 SSH Agent Identity Loading Hardening](./36-ssh-agent-identity-loading-hardening.md) — `done`
3. [33 JJ-Backed Forgejo Spike](./33-jj-backed-forgejo-spike.md) — `done`
4. [32 Public Repo Stress Analysis Demo](./32-public-repo-stress-analysis-demo.md) — `done`
5. [31 Forgejo-Shell Demo Surface On Vaglio](./31-forgejo-shell-vaglio-demo-surface.md) — `done`
6. [30 Vaglio Roundtable Reactivation](./30-vaglio-roundtable-reactivation.md) — `done`
7. [36 Vaglio 25.11 Landing Transition](./36-vaglio-25-11-landing-transition.md) — `done`
8. [35 Agent-Roundtable Standalone Service Fix](./35-agent-roundtable-standalone-service-fix.md) — `done`
