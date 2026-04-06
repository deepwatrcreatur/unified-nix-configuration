# 10 Remove Gstack And Browse Coupling

Status: `done`

Suggested branch: `refactor/tooling-remove-gstack`

## Goal

Remove Garry Tan's `gstack` integration and any repo instructions that depend on
it so agent workflows no longer assume Claude-specific browsing helpers.

## Why

The repo currently carries `gstack` guidance in instruction docs. That creates a
tooling dependency that is not part of the repo's actual systems configuration
model and is awkward for other agents to follow consistently.

## Scope

- audit repo docs and instructions for `gstack` references
- remove or replace `gstack`-specific browsing guidance
- keep any replacement guidance generic enough for multiple agents
- leave a short note if some `gstack`-specific workflow is intentionally kept
  outside this repo

## Non-Goals

- rewriting every agent guide from scratch
- adding a new browser automation stack in the same PR
- changing unrelated Claude or Codex instructions

## Validation

- repo docs no longer assume `gstack` is installed
- remaining agent instructions are internally consistent
- no stale references point agents at missing local tooling

## Implementation

- Audited all repo docs, agent guides, and CLAUDE.md for `gstack` and `/browse`
  references. Only CLAUDE.md carried a live gstack-specific instruction block.
- Replaced the `## gstack` section in CLAUDE.md with a generic `## Web Browsing
  and External Resources` section that does not assume any specific browser
  automation stack is installed.
- The `.claude/skills/gstack/` tooling installation is intentionally left
  outside this PR's scope — it lives in a gitignored local config path and is
  not part of the repo's systems configuration model.
