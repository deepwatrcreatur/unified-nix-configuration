# 27 Gemini CLI Managed Auth Path

Status: `done` (documented in [`docs/tooling-managed-auth.md`](../tooling-managed-auth.md))

Suggested branch: `fix/tooling-gemini-cli-auth-path`

## Goal

Make the repo-managed authentication story for `gemini-cli` explicit and
reliable, whether that means a wrapper, an OAuth credential bootstrap path, or
an intentional no-wrapper decision.

## Why

`gemini-cli` is part of the shared coding-agent package set, but unlike `gh`
and other wrapped tools, its managed auth path is not currently obvious from
the queue or wrapper policy. The workstation config already provisions Gemini
OAuth credentials, so the missing piece is operational clarity and, if needed,
canonical command wiring.

## Scope

- audit how `gemini-cli` authenticates in the current package and host setup
- decide whether the repo should wrap `gemini-cli`, seed credentials via fnox,
  or rely on the existing OAuth credential file path
- if a wrapper is useful, expose it under the canonical `gemini`/`gemini-cli`
  path used by operators and agents
- document the expected credential precedence and debugging path

## Non-Goals

- replacing Gemini OAuth with a different auth model in one PR
- wrapping tools that do not materially share the same auth path
- broad shell cleanup unrelated to Gemini auth

## Validation

- `gemini-cli` works on an affected host using the repo-managed credential path
- the chosen integration is documented in the repo rather than only implied in
  host-specific chat history
- fallback or raw execution remains available for debugging

## Notes

This work item is intentionally phrased more broadly than "add wrapper" because
Gemini may fit better as a managed credential path than as an env-injection
wrapper.
