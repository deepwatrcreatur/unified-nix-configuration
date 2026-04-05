# 12 Retire Home Manager SOPS Secrets Activation

Status: `in-progress`

Suggested branch: `refactor/tooling-retire-hm-sops-activation`

## Goal

Decide whether `modules/home-manager/secrets-activation.nix` is still an
intentional compatibility layer or should now be retired in favor of the
agenix-first secret path.

## Why

This module is still imported in active user configs, and it is large enough to
look authoritative. But it remains deeply SOPS-centric and overlaps with newer
agenix-first modules such as:

- `modules/home-manager/user-secrets.nix`
- `modules/home-manager/agenix-user-secrets.nix`

That creates a real risk that future fixes will land in the wrong secret path
again.

## Scope

- audit where `modules/home-manager/secrets-activation.nix` is still imported
- determine which hosts still depend on it for real behavior
- either:
  - retire it and move any still-needed behavior into the agenix-first path, or
  - mark it explicitly as a temporary compatibility module with strong comments
    and narrower scope
- update user config imports accordingly

## Non-Goals

- redesigning all user secret consumers in one PR
- deleting historical docs that explain earlier SOPS behavior
- breaking Debian/Proxmox/root user workflows without a replacement

## Validation

- affected Home Manager configs still evaluate cleanly
- the intended user-secret path is easier to identify from imports alone
- future agents are less likely to patch the wrong secret activation module
