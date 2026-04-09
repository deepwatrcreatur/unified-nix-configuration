# 26 Claude Code Managed Auth Path

Status: `done` (documented in [`docs/tooling-managed-auth.md`](../tooling-managed-auth.md))

Suggested branch: `fix/tooling-claude-code-auth-path`

## Goal

Decide and implement the repo-managed authentication path for `claude-code`
so operators and agents are not relying on ad hoc ambient shell state.

## Why

The repo now has explicit wrapper or managed-secret behavior for several tools,
but `claude-code` is still effectively raw. That leaves a gap between the
documented wrapper policy and the actual agent toolchain.

## Scope

- determine which credential path the packaged `claude-code` actually supports
  in this environment
- decide whether the right answer is a canonical wrapper, a fnox-managed secret
  source, or an explicit no-wrapper policy
- if a wrapper is appropriate, expose it under the canonical `claude-code`
  command name while preserving a raw path for debugging
- document the expected operator and agent behavior

## Non-Goals

- redesigning all Anthropic secret storage in one PR
- changing unrelated CLI wrappers
- forcing a wrapper if `claude-code` is login/session based rather than
  token/env based

## Validation

- `claude-code` launches using the repo-managed auth path on an affected host,
  or the repo contains a clear documented no-wrapper decision
- shell aliases or package selection resolve to the intended command path
- fallback/debug behavior remains obvious

## Notes

This should be treated as a wrapper-fit decision as much as an implementation
task. A good outcome may be "do not wrap, document why" if that is the more
correct integration for the tool.
