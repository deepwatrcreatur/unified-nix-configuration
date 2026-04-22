# 26 Remove GPG Modules

Status: `in-progress`

Suggested branch: `feat/tooling-remove-gpg-modules`

## Goal

Delete the five GPG HM modules and `ssh-auth-session.nix` (which was
only activated when gpg-agent SSH support was enabled) once no host
imports them.

## Why

Dead code. All hosts will have migrated to SSH signing by item 25.
Removing the files prevents future accidental re-use and shrinks the
module surface.

## Scope

Delete:
- `modules/home-manager/gpg-agent-cross-de.nix`
- `modules/home-manager/gpg-agent-ssh.nix`
- `modules/home-manager/gpg-cli.nix`
- `modules/home-manager/gpg-desktop-linux.nix`
- `modules/home-manager/gpg-mac.nix`
- `modules/home-manager/common/ssh-auth-session.nix` (guarded by
  `services.gpg-agent.enable` — no longer needed)

Verify nothing else imports these files before deleting.

## Non-Goals

- Removing `gnupg` from any host if it's used for non-signing purposes
  (e.g. secret decryption via age). Check before deleting.

## Validation

- `grep -r "gpg-agent\|gpg-cli\|gpg-mac\|gpg-desktop\|ssh-auth-session"
  modules/ users/` returns zero results after deletion
- Full eval of a nixos and a darwin host succeeds

## Dependencies

- Item 25 must be merged first
