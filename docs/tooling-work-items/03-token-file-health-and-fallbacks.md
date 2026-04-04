# 03 Token File Health And Fallbacks

Status: `ready`

Suggested branch: `fix/tooling-token-file-health`

## Goal

Harden the repo against broken secret materialization so hosts do not end up
with files like `~/.config/git/github-token` containing an error message instead
of a real token.

## Why

- `inference1` currently has `~/.config/git/github-token`, but the file contains
  a SOPS decryption failure message rather than a token.
- That breaks both global environment export and any wrapper flow that treats
  the file as authoritative.
- A bad token file is worse than no token file because the failure mode is
  misleading and propagates into build/rebuild commands.

## Scope

- audit the user secret activation path that writes `~/.config/git/github-token`
- ensure failed decryptions do not overwrite a valid token file with stderr
- prefer atomically writing only verified token contents
- document fallback precedence between:
  - user token file
  - agenix user secret
  - system-level secret under `/run/agenix` or `/run/secrets`
- add one small validation/check or guardrail if practical

## Non-Goals

- a full secret-management redesign across all repos
- changing unrelated token consumers in the same PR

## Validation

- failed decryptions leave the previous valid token intact or leave no token file
- successful activation writes only the token, not error output
- docs make the fallback order explicit
