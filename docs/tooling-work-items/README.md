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

1. [24 SSH Commit Signing — Core Modules](./24-ssh-commit-signing-modules.md) — `in-progress`
2. [25 SSH Commit Signing — Host Wiring](./25-ssh-signing-host-wiring.md) — `ready`, depends on 24
3. [26 Remove GPG Modules](./26-remove-gpg-modules.md) — `ready`, depends on 25
