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

1. [`24-agent-instruction-entrypoint-contract.md`](./24-agent-instruction-entrypoint-contract.md) - `in-progress`
2. [`25-gh-managed-auth-followup-hardening.md`](./25-gh-managed-auth-followup-hardening.md) - `done`
3. [`24-gh-fnox-wrapper-completion.md`](./24-gh-fnox-wrapper-completion.md) - `in-progress`
4. [`25-agent-build-cache-fallback-and-trust.md`](./25-agent-build-cache-fallback-and-trust.md) - `in-progress`
5. [`14-dcg-pretooluse-guard.md`](./14-dcg-pretooluse-guard.md) - `done`
6. [`27-gemini-cli-managed-auth-path.md`](./27-gemini-cli-managed-auth-path.md) - `done`
7. [`15-cass-session-search-integration.md`](./15-cass-session-search-integration.md) - `done`
8. [`16-cm-procedural-memory-bootstrap.md`](./16-cm-procedural-memory-bootstrap.md) - `done`
9. [`17-agent-mail-workflow-fit.md`](./17-agent-mail-workflow-fit.md) - `done`
10. [`18-beads-task-graph-integration.md`](./18-beads-task-graph-integration.md) - `done`
11. [`19-repo-updater-sync-workflow.md`](./19-repo-updater-sync-workflow.md) - `ready`
12. [`20-robot-triage-prioritization.md`](./20-robot-triage-prioritization.md) - `ready`
13. [`21-fleet-integration-flake-design.md`](./21-fleet-integration-flake-design.md) - `ready`
14. [`22-mem0-integration-fleet-memory.md`](./22-mem0-integration-fleet-memory.md) - `ready`
15. [`23-cross-agent-memory-extraction-pipeline.md`](./23-cross-agent-memory-extraction-pipeline.md) - `ready`
