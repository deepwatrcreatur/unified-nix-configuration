# 24 Agent Instruction Entrypoint Contract

Status: `in-progress`

Suggested branch: `docs/tooling-agent-entrypoint-contract`

## Goal

Make the workspace-level agent instruction entrypoint for
`/home/deepwatrcreatur/flakes` explicit, resolvable, and stable.

## Why

Current agent startup context references `@RTK.md` from the flakes workspace
root, but that file does not exist there. That creates avoidable ambiguity at
the start of work:

- agents cannot resolve the referenced instruction file locally
- repo-local `AGENTS.md` files become harder to discover consistently
- future agent runs risk drifting based on chat history instead of a durable
  entrypoint

This is a tooling contract problem, not just a missing doc file.

## Scope

- add a canonical workspace-level instruction file at the flakes root
- make the relationship between the workspace entrypoint and repo-local
  `AGENTS.md` files explicit
- ensure the workspace entrypoint tells agents how to find the repo-specific
  instructions that should extend it
- keep the root guidance short and stable rather than duplicating full
  per-repo policy

## Non-Goals

- rewriting every repo-local `AGENTS.md`
- inventing a large new agent framework
- moving queue ownership out of the existing repo docs

## Validation

- `RTK.md` exists at `/home/deepwatrcreatur/flakes/RTK.md`
- the workspace-level instruction reference resolves without guesswork
- the entrypoint clearly directs agents to the correct repo-local guidance

## Notes

The best solution is a small root-level contract:

- root `RTK.md` as the canonical entrypoint
- optional root `AGENTS.md` that points to it for file-based discovery
- repo-local `AGENTS.md` files remain the authoritative extension layer
