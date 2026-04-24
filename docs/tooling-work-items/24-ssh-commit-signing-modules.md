# 24 SSH Commit Signing — Core Modules

Status: `done`

Suggested branch: `feat/tooling-ssh-signing-modules`

## Goal

Replace GPG commit signing with SSH key signing across the fleet.
Deliver two new HM modules and update `git.nix` / `users/root/git.nix`.

## Why

GPG adds pinentry complexity, platform-specific agents (pinentry-mac,
pinentry-gtk2, pinentry-curses), and per-host workarounds. SSH signing
uses the same key already in the SSH agent — no extra daemon, no
passphrase prompts for agents, identical behaviour on NixOS and darwin.

## Scope

- `modules/home-manager/git-ssh-signing.nix`
  - sets `gpg.format = "ssh"`, `commit.gpgsign = true`
  - sets `user.signingkey = "~/.ssh/id_ed25519.pub"`
  - sets `gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers"`
  - `home.activation` script writes `allowed_signers` from the live pubkey
- `modules/home-manager/ssh-agent.nix`
  - Linux: `services.ssh-agent.enable = true`
  - Darwin: `programs.ssh.extraConfig` with `AddKeysToAgent yes` / `UseKeychain yes`
- `modules/home-manager/git.nix`
  - switch `user.signingkey` to SSH pubkey path
  - replace `gpg.format` (remove implicit OpenPGP default)
  - remove all `GPG_TTY` shell export blocks (bash/zsh/fish/nushell)
- `users/root/git.nix`
  - switch `signing.key` to SSH pubkey path
  - remove `0x` GPG key ID

## Non-Goals

- Host wiring (done in item 25)
- Deletion of GPG modules (done in item 26)

## Validation

- `nix-instantiate --parse` on both new modules
- eval `nixosConfigurations.workstation.config.programs.git.settings`
  confirms `gpg.format = "ssh"` and no `gpgsign` referencing the old key

## Dependencies

None — can land independently.

## Follow-up

- Item 25: wire all hosts
- Item 26: remove GPG modules
