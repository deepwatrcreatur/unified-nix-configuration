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
2. [`25-gh-managed-auth-followup-hardening.md`](./25-gh-managed-auth-followup-hardening.md) - `ready`
3. [`24-gh-fnox-wrapper-completion.md`](./24-gh-fnox-wrapper-completion.md) - `in-progress`
4. [`26-claude-code-managed-auth-path.md`](./26-claude-code-managed-auth-path.md) - `done`
5. [`27-gemini-cli-managed-auth-path.md`](./27-gemini-cli-managed-auth-path.md) - `done`
6. [`25-agent-build-cache-fallback-and-trust.md`](./25-agent-build-cache-fallback-and-trust.md) - `ready`
7. [`14-dcg-pretooluse-guard.md`](./14-dcg-pretooluse-guard.md) - `ready`
8. [`15-cass-session-search-integration.md`](./15-cass-session-search-integration.md) - `ready`
9. [`16-cm-procedural-memory-bootstrap.md`](./16-cm-procedural-memory-bootstrap.md) - `ready`
10. [`17-agent-mail-workflow-fit.md`](./17-agent-mail-workflow-fit.md) - `ready`
11. [`18-beads-task-graph-integration.md`](./18-beads-task-graph-integration.md) - `ready`
12. [`19-repo-updater-sync-workflow.md`](./19-repo-updater-sync-workflow.md) - `ready`
13. [`20-robot-triage-prioritization.md`](./20-robot-triage-prioritization.md) - `ready`
14. [`21-fleet-integration-flake-design.md`](./21-fleet-integration-flake-design.md) - `ready`
15. [`22-mem0-integration-fleet-memory.md`](./22-mem0-integration-fleet-memory.md) - `ready`
16. [`23-cross-agent-memory-extraction-pipeline.md`](./23-cross-agent-memory-extraction-pipeline.md) - `ready`
17. [`13-codex-bubblewrap-dependency.md`](./13-codex-bubblewrap-dependency.md) - `done`
