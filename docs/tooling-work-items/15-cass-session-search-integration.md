# 15 CASS Session Search Integration

Status: `done`

Suggested branch: `feat/tooling-cass-session-search`

## Implementation Notes

- Packaged `cass` (Coding Agent Session Search) in `nix-session-search` repository.
- Integrated `nix-session-search` as a flake input.
- Added `programs.session-search` Home Manager module in
  `modules/home-manager/common/session-search.nix`.
- Enabled `hourly` auto-indexing of agent sessions via systemd user timer.
- Added `qs` (quick search) and `cs` (TUI search) shell aliases for agents and humans.
- Added `~/.cass-guide.md` documentation for future agents.

## Goal

Make prior coding-agent sessions searchable from this environment so recurring
repo problems can be rediscovered quickly instead of relying on chat scrollback
or scattered handoff docs.

## Why

This repo already accumulates durable operational knowledge in
[`docs/`](../), [`AGENTS.md`](../../AGENTS.md), and
[`agent-handoff-plan-2026-04-02.md`](../agent-handoff-plan-2026-04-02.md), but
there is still a gap between "what the repo documents" and "what past sessions
already discovered." A CASS-style index is a good fit because this codebase has
many recurring tasks where prior debugging context matters:

- agenix and secret migration work
- router and remote-host rebuild failures
- upstream flake integration and hotfixes
- agent-tooling setup across multiple hosts

## Scope

- identify which local session directories are worth indexing first
  (`Claude`, `Codex`, and any other agent logs that are actually present)
- decide whether the initial rollout should be host-local only or shared via a
  synced path
- package or install the session-search tool in a reproducible way
- add a minimal operator-facing command/documentation layer so agents can query
  past sessions intentionally
- document privacy, retention, and repo-boundary expectations

## Non-Goals

- inventing a new long-form documentation system
- automatically turning every session into repo docs
- solving procedural memory extraction in the same PR

## Validation

- a known historical topic can be found by search
- the search command works from an affected host without ad hoc setup
- docs explain where the index reads from and how to refresh it
