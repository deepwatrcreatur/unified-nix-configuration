# 10 Remove Gstack And Browse Coupling

Status: `ready`

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
