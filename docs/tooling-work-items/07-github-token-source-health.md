# 07 GitHub Token Source Health

Status: `done`

Suggested branch: `fix/tooling-github-token-health`

## Goal

Make GitHub token sourcing fail safe and observable, so hosts do not silently
write decryption error text into `~/.config/git/github-token` and then use that
garbage as if it were a valid token.

## Why This Exists

On `inference1`, `~/.config/git/github-token` contained a SOPS decryption error
message rather than a token. That broke authenticated GitHub API access during
`nixos-rebuild`, while making the failure mode look like a normal token file.

The repo currently mixes several token paths:

- user token files under `~/.config/git/github-token`
- agenix-managed paths
- shell-exported `GITHUB_TOKEN`
- `fnox` seed sources

This needs a clearer health model and safer fallback behavior.

## Scope

- audit the current GitHub token write path in Home Manager and any system-side
  secret provisioning used by flake operations
- prevent obvious non-token content from being installed as
  `~/.config/git/github-token`
- make secret bootstrap prefer valid agenix/system sources over best-effort
  decrypt attempts that can leave misleading files behind
- add clear warnings for missing or unreadable token sources
- document the short-term rebuild escape hatch:
  passing a real token explicitly to `nixos-rebuild` when host-local token files
  are unhealthy

## Non-Goals

- fully completing the wrapper-first migration away from shell-exported
  `GITHUB_TOKEN`
- redesigning every secret in the repo
- adding provider-specific token validation beyond basic sanity checks

## Validation

- unhealthy decrypt output is not written to `~/.config/git/github-token`
- a host with broken user secret decryption does not masquerade as having a
  valid GitHub token
- flake operations still work when valid agenix/system token sources are
  available
- docs leave future operators with a clear recovery path for one-off rebuilds
