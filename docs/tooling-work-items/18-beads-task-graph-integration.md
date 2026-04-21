# 18 Beads Task Graph Integration

Status: `done`

Suggested branch: `feat/tooling-beads-integration`

## Goal

Migrate the flat markdown work-item queue into `beads_rust` (via the
repo-managed `beads-rust` command) to enable
programmatic dependency tracking and "ready" task surfacing for agents.

## Why

This repo's `docs/tooling-work-items/` queue is currently a flat, manually
ranked markdown list. While simple, it does not represent the real dependency
edges between tasks (e.g., CASS should land before CM). `beads` allows an
agent to ask `beads-rust ready --json` and get a list of unblocked work, removing the
need for human-curated ranking in READMEs.

## Scope

- initialize `beads` in this repo (`beads-rust init`)
- ingest the current `ready` and `in-progress` items from the markdown queue
- define dependency edges between related tasks (e.g., CASS -> CM)
- document the new workflow:
  - `beads-rust add` for new tasks
  - `beads-rust start` / `beads-rust finish` for state transitions
  - how to view the graph via `beads-rust status`
- evaluate whether the `.beads/` SQLite/JSONL data should be committed
  (standard beads practice)

## Non-Goals

- migrating the router's backlog (out of scope for repo tooling)
- replacing the markdown files entirely if they are still useful for long-form
  discussion (beads can link to them)

## Implementation (current)

- `docs/beads-migration-plan.md` moved from a deferred design to an
  in-progress wiring state, with `.beads/` layout, ignore rules, and
  docs checklist updated.
- `.beads/issues.jsonl` is committed empty and `.beads/*.db*` are gitignored;
  operators can run `beads-rust init` and migrate queues once the repo-managed
  CLI is installed.
- `scripts/beads-migrate-tooling.sh` migrates the current tooling queue's
  `ready` and `in-progress` items into beads when `beads-rust` is available.
- `START-HERE.md` and `agent-prompts.md` for both tooling and router now
  describe beads-aware workflows while preserving README-based fallbacks.

## Validation

- `beads-rust ready` correctly identifies unblocked tasks
- `beads-rust status` shows a coherent graph of current work
- docs explain the shift from "Ranked Queue" to "Dependency Graph"
