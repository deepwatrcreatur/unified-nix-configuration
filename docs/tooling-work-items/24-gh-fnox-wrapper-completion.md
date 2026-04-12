# 24 GH Fnox Wrapper Completion

Status: `in-progress`

Suggested branch: `fix/tooling-gh-fnox-wrapper`

## Goal

Finish the GitHub CLI migration away from shell-exported tokens by making `gh`
work through the repo's `fnox`-style secret path instead of depending on a
fragile ambient `GH_TOKEN`.

## Why

The repo has already reduced token-export assumptions in the shell, but agents
are still failing to use `gh` because the wrapper-first migration is
incomplete:

- `gh auth status` reports invalid credentials
- bot/agent workflows that rely on `gh pr view`, `gh pr checks`, or merge
  commands are blocked
- the earlier wrapper work only landed `opencode`; `gh` did not become a
  reliable wrapped command in practice

This is now an operational tooling gap, not just a cleanup idea.

## Scope

- audit how `gh` is currently exposed in Home Manager aliases/packages
- determine the cleanest `fnox`-backed or equivalent repo-managed path for
  supplying GitHub credentials to `gh`
- make the canonical `gh` command resolve to the managed path when available
- preserve an obvious raw/bypass path for debugging if needed
- document the operator and agent expectations clearly

## Non-Goals

- redesigning all GitHub secret storage in one PR
- changing unrelated agent CLI wrappers unless they materially share the same
  fix path
- depending on manual `gh auth login` as the normal solution

## Validation

- `gh auth status` succeeds on an affected host with the managed token path
- common repo workflows like `gh pr view` and `gh pr checks` work again
- the fallback behavior is explicit when the wrapper or token source is absent

## Notes

This should build on the earlier wrapper-policy and token-health work instead
of reopening those design questions.

## Current implementation state

- Active branch: `fix/tooling-gh-fnox-wrapper`
- Worktree: `/tmp/unified-gh-fnox-wrapper`
- PR: #97 (`fix(tooling): prefer managed token files in gh wrapper`)
- CI: inventory/module/security checks passing; GitHub reports `mergeable_state = dirty` (needs rebase/refresh against `main`).

## Next actions

- Rebase `fix/tooling-gh-fnox-wrapper` onto `main` and resolve conflicts.
- Re-run inventory/module checks locally if conflict resolution touches Nix modules.
- If CI remains green and local checks pass, merge PR #97 and then flip this item to `done`.
