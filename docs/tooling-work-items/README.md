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

1. [30 Vaglio Roundtable Reactivation](./30-vaglio-roundtable-reactivation.md) — `in-progress`
2. [31 Forgejo-Shell Demo Surface On Vaglio](./31-forgejo-shell-vaglio-demo-surface.md) — `ready`
3. [32 Public Repo Stress Analysis Demo](./32-public-repo-stress-analysis-demo.md) — `ready`
4. [33 JJ-Backed Forgejo Spike](./33-jj-backed-forgejo-spike.md) — `ready`

## Recently Completed

1. [35 Agent-Roundtable Standalone Service Fix](./35-agent-roundtable-standalone-service-fix.md) — `done`
2. [34 Vaglio Proxmox LXC Bring-Up](./34-vaglio-proxmox-lxc-bring-up.md) — `done`
3. [24 SSH Commit Signing — Core Modules](./24-ssh-commit-signing-modules.md) — `done`
4. [25 SSH Commit Signing — Host Wiring](./25-ssh-signing-host-wiring.md) — `done`
5. [26 Remove GPG Modules](./26-remove-gpg-modules.md) — `done`
