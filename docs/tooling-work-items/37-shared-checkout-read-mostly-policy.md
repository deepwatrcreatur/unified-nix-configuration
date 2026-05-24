# 37 Shared Checkout Read-Mostly Policy

Status: `ready`
Suggested branch: `docs/shared-checkout-read-mostly-policy`
Priority: `high`

## Goal

Make the shared repo checkout explicitly read-mostly / sync-only for agent work,
and move the worktree-first mutation rule into the root guidance that every
agent sees before editing.

## Why

- Repeated cleanup/recovery work shows the current guidance is directionally
  right but too advisory.
- Agents still treat the shared checkout as normal writable space because the
  strongest rule is not surfaced at the root entrypoints.
- Round 116 converged that the correct default is:
  - inspect / sync / land in the shared checkout
  - edit in a disposable worktree

## Scope

1. Add one canonical rule to the root agent-entry docs (`AGENTS.md`, RTK-linked
   entrypoints, and any closely coupled top-level guidance):
   - shared checkout is read-mostly / sync-only
   - agent edits belong in disposable worktrees
2. Update `docs/design/ORCHESTRATION_GUIDE.md` and closely related queue docs to
   point to that canonical policy instead of restating softer variants.
3. Add one short decision table covering:
   - inspect
   - sync / fast-forward
   - edit
   - publish / land
   - live host mutation
4. Remove or redirect any duplicate guidance that weakens the canonical wording.

## Non-Goals

- Implementing a preflight guard or hook
- Building board-level resource leasing
- Rewriting all repo process docs at once

## Validation

- A new agent starting at the repo root can see the write-boundary rule without
  searching secondary documents.
- The shared checkout vs worktree split is stated consistently across the main
  entrypoints.
- The resulting policy matches Round 88's live-resource single-writer boundary
  rather than conflating branch work with host mutation locks.

## Notes

This is the policy-surfacing half of the Round 116 conclusion. It should land
before or alongside the preflight guard so the wrapper points at one stable,
human-readable rule.
