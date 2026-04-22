# 15 CASS Session Search Integration

Status: `done`

Suggested branch: `feat/tooling-cass-session-search`

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

## Implementation (current)

- `scripts/cass-session-search.sh` implements a small wrapper around
  `ripgrep` that searches local agent session directories.
- `modules/home-manager/common/cass-session-search.nix` packages this as
  a `cass-session-search` binary and is imported by
  `modules/home-manager/common/coding-agents.nix`, with
  `programs.cass-session-search.enable` defaulting to `true`.
- By default, the command searches these roots when they exist:
  `$HOME/.copilot/session-state`, `$HOME/.claude/sessions`, and
  `$HOME/.gemini/history`. Operators can override this via the
  `CASS_SESSION_ROOTS` environment variable.
- The behavior and privacy model are documented in
  `docs/cass-session-search.md`, and `AGENTS.md` links to that doc for
  agent-facing discovery.

## Validation

- a known historical topic can be found by search
- the search command works from an affected host without ad hoc setup
- docs explain where the index reads from and how to refresh it
