# 06 SOPS Compatibility Layer Cleanup

Status: `done`

Suggested branch: `refactor/tooling-sops-compat-cleanup`

## Goal

Reduce or remove stale SOPS-era fallback logic now that this repo’s active
secret model is agenix-based, while preserving any truly necessary short-term
migration paths.

## Why

The repo no longer appears to use `nix-sops-dir-secrets`, and the main flake
secret path is now agenix. But several modules and docs still refer to:

- `~/.config/sops/...`
- direct `sops -d ...` fallbacks
- older activation logic that assumes user-scoped SOPS keys exist

That creates confusion about the real source of truth and makes it harder for
agents to tell whether a SOPS path is still required or just historical debt.

## Scope

- inventory the remaining SOPS references in active modules and operational
  docs
- separate them into:
  - still-needed compatibility fallbacks
  - migration docs / historical notes
  - stale logic that should be removed
- remove or clearly mark stale SOPS fallback paths where agenix is now the
  intended source of truth
- add concise comments where temporary compatibility remains intentionally

## Non-Goals

- deleting all historical migration documentation
- redesigning the entire secret model in one PR
- forcing non-NixOS hosts onto a new secret workflow without checking whether
  they still depend on SOPS-era bootstrap behavior

## Validation

- active secret modules still evaluate cleanly
- agenix-first hosts continue to work without relying on hidden SOPS paths
- remaining SOPS references are clearly intentional rather than accidental

## Notes

Prefer tightening active modules first. Historical docs can be downgraded or
annotated later if they are useful for migration history.

## Implementation

- Updated top-level agent docs (`AGENTS.md`, `agents.md`) to describe agenix as
  the primary secrets backend and SOPS-nix as a limited compatibility layer.
- Clarified SOPS compatibility responsibilities in
  `modules/home-manager/user-secrets.nix` and
  `modules/home-manager/secrets-activation.nix` so that SOPS usage is clearly
  documented as a fallback.
- Updated `docs/github-token-fallbacks.md` to explain that
  `secrets-activation.nix` only applies on legacy SOPS hosts; agenix-first hosts
  rely on `user-secrets.nix` and agenix paths instead.
