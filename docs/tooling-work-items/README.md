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

1. `01-agent-cli-fnox-wrappers.md`
2. `02-api-and-proxmox-wrapper-candidates.md`
3. `03-wrapper-policy-and-rollout.md`
4. `04-sudo-wrapper-path-precedence.md`
5. `05-github-token-source-health.md`
6. `06-sops-compatibility-layer-cleanup.md`
7. `07-agenix-helper-flake-evaluation.md`
8. `08-agenix-migration-layer-stabilization.md`
9. `09-agenix-helper-flake-threshold.md`
10. `10-den-legacy-inventory-reduction.md`
11. `11-host-metadata-source-of-truth.md`
12. `12-retire-home-manager-sops-secrets-activation.md`
