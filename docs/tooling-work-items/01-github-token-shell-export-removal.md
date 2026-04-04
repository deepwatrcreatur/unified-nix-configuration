# 01 GitHub Token Shell Export Removal

Status: `done`

Suggested branch: `feat/tooling-remove-global-github-token-export`

## Goal

Stop exporting `GITHUB_TOKEN` globally in every interactive shell once command
wrapper coverage is sufficient, so secrets are injected only for commands that
actually need them.

## Why

- `modules/home-manager/git.nix` currently exports `GITHUB_TOKEN` into bash,
  zsh, fish, and nushell for every shell session.
- That increases accidental exposure risk through subprocesses, debugging, and
  environment inspection.
- The repo already has partial `fnox` support plus canonical wrappers for `gh`
  and `bw`, so the next step is to finish the migration away from ambient token
  exposure.

## Scope

- inventory every place `GITHUB_TOKEN` is exported into shell startup
- remove the unconditional shell exports for supported hosts/shells
- preserve GitHub CLI auth behavior through wrapped commands or explicit
  credential helper usage
- add concise comments explaining why the token is intentionally *not* exported
  globally anymore

## Non-Goals

- redesigning all secret management in one PR
- wrapping unrelated build tools like `nixos-rebuild`, `nh`, or `just`

## Validation

- affected Home Manager configs evaluate cleanly
- `gh` still works through the intended wrapped/credential-helper path
- new shells no longer inherit `GITHUB_TOKEN` by default
- docs clearly state the policy change and fallback path

## Implementation

- Removed `GITHUB_TOKEN` exports from bash, zsh, fish, and nushell init in
  `modules/home-manager/git.nix`.
- Left GPG/SSH environment logic unchanged.
- Rely on `gh-fnox` and `fnox` seed sources plus
  `modules/home-manager/user-secrets.nix` to supply tokens when needed instead
  of ambient shell exports.
- `nix flake check` for this repo currently fails on a pre-existing missing
  `modules/nixos/bootstrap/default.nix` import; this branch does not change
  that behavior.
