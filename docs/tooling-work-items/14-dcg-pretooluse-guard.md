# 14 DCG PreToolUse Guard

Status: `ready`

Suggested branch: `feat/tooling-dcg-guard`

## Goal

Add a repo-supported destructive-command guard for coding agents so dangerous
commands are blocked before execution rather than relying only on prose rules in
agent instructions.

## Why

This repo manages real infrastructure and already documents a lot of operational
guardrails in [`AGENTS.md`](../../AGENTS.md) and [`CLAUDE.md`](../../CLAUDE.md),
but those protections are advisory. The Flywheel DCG model is useful here
because it addresses an actual gap in the current setup: pre-execution
enforcement for obviously destructive git and filesystem actions.

The fit is strong because this repo already enables agent hook infrastructure in
[`modules/home-manager/common/coding-agents.nix`](../../modules/home-manager/common/coding-agents.nix).

## Scope

- audit the existing agent-hook surfaces provided by `programs.rtk-hooks`
- determine the cleanest integration point for a DCG-like PreToolUse guard for
  Claude Code first, and note whether Codex/Gemini can share the same policy
- package or install the guard in a reproducible way suitable for this repo
- start with narrow, high-confidence protections:
  - destructive git operations
  - recursive deletes / force deletes
  - obviously destructive database or cloud patterns only if already relevant
- document how to intentionally bypass the guard for known-safe one-off cases

## Non-Goals

- implementing SLB-style two-person approvals for normal repo work
- blocking ordinary rebuild, eval, or worktree commands
- broad policy debates unrelated to destructive command prevention

## Validation

- a representative dangerous command is blocked before execution
- ordinary day-to-day commands used in this repo still run normally
- the relevant Home Manager configuration evaluates cleanly on affected hosts
- docs make the guard behavior and bypass path obvious to future agents
