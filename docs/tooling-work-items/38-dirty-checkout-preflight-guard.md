# 38 Dirty Checkout Preflight Guard

Status: `ready`
Suggested branch: `feat/dirty-checkout-preflight-guard`
Priority: `high`

## Goal

Add a lightweight preflight helper for agent write-mode work so mutating from a
dirty or ambiguous shared checkout stops being frictionless.

## Why

- Round 116 converged that the highest-leverage intervention is a small
  pre-write guard rather than more prose alone.
- Right now agents can start editing immediately in a dirty shared checkout with
  no local resistance.
- The result is later cherry-pick recovery, patch replay, and uncertainty about
  which dirt is safe to keep.

## Scope

1. Implement a small helper or wrapper (shell function, script, or repo-local
   command) that checks at least:
   - `git status --porcelain`
   - whether the current checkout is detached or on a shared branch tip
   - whether the branch is ahead/behind its upstream in a way that makes landing
     risky
2. If the checkout is dirty or ambiguous, print a clear action message that
   points the agent/operator toward creating a disposable worktree.
3. Prefer a guard shape that can be reused by repo-local skills or shell
   wrappers later.
4. Document the intended call sites:
   - before the first file edit
   - before commit
   - before push / publication

## Non-Goals

- Full orchestrator enforcement or daemon integration
- Multi-agent locking for live hosts
- Solving artifact-ignore hygiene by itself

## Validation

- Running the helper in a clean worktree reports safe-to-edit state.
- Running it in a dirty shared checkout produces a visible warning or failure
  with the relevant files/conditions.
- The guidance it prints matches the canonical shared-checkout policy.

## Notes

Hard-fail vs warn-only is still an implementation choice. Round 116 converged
more strongly on “must exist” than on the exact severity, so the first slice can
start with a strong warning if that lands faster.
