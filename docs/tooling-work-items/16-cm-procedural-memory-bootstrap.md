# 16 CM Procedural Memory Bootstrap

Status: `ready`

Suggested branch: `docs/tooling-cm-procedural-memory`

## Goal

Decide whether this repo should adopt a lightweight cross-agent procedural
memory layer, and if so, bootstrap it around the highest-value recurring
workflows.

## Why

An independent assessment of Agent Flywheel suggests CM is not actually
equivalent to Claude Code's built-in memory. Claude memory is provider-specific
and primarily acts as local standing context, while CM is aimed at extracting
reusable procedures from past work so different agents can retrieve and apply
them later.

That does not mean CM should be adopted blindly. This repo already has strong
written memory in [`AGENTS.md`](../../AGENTS.md), [`CLAUDE.md`](../../CLAUDE.md),
queue docs, and handoff plans. The missing feature is not "memory exists at
all"; it is the lack of a deliberate pipeline for promoting repeated session
discoveries into reusable, queryable procedures.

## Scope

- compare the repo's current memory surfaces against a CM-style workflow:
  - agent instruction files
  - queue docs and handoff plans
  - searchable session history if item 15 lands
- identify the smallest useful adoption path
- if the answer is yes, define a minimal store and workflow for recurring
  procedures such as:
  - remote rebuild and tmux patterns
  - agenix secret editing and migration
  - fnox-backed command usage
  - worktree / branch hygiene for parallel agents
- document when knowledge belongs in repo docs versus procedural memory

## Non-Goals

- replacing repo documentation with opaque memory artifacts
- reproducing the full Flywheel case-study workflow
- committing to a vendor-specific memory format without a clear payoff

## Validation

- the resulting doc or implementation makes a clear keep/reject decision
- if kept, at least a small seed set of recurring procedures is captured
- the chosen approach is understandable to both Claude-oriented and
  non-Claude-oriented agents
