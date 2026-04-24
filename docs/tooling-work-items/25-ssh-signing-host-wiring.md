# 25 SSH Commit Signing — Host Wiring

Status: `done`

Suggested branch: `feat/tooling-ssh-signing-hosts`

## Goal

Replace all GPG module imports across every host with the new SSH
signing + SSH agent modules from item 24.

## Why

Items 24 delivers the modules; this item wires them in everywhere so
the full fleet drops its gpg-agent dependency.

## Scope

Replace GPG imports in:

### deepwatrcreatur user (8 hosts)
- `users/deepwatrcreatur/hosts/macminim4/default.nix` — `gpg-mac.nix`
- `users/deepwatrcreatur/hosts/workstation/default.nix` — `gpg-agent-cross-de.nix`
- `users/deepwatrcreatur/hosts/homeserver/default.nix` — `gpg-agent-ssh.nix`
- `users/deepwatrcreatur/hosts/inference-vm/default.nix` — `gpg-agent-ssh.nix`
- `users/deepwatrcreatur/hosts/attic-cache/default.nix` — `gpg-agent-ssh.nix`
- `users/deepwatrcreatur/hosts/podman/default.nix` — `gpg-agent-ssh.nix`
- `users/deepwatrcreatur/hosts/authentik-host/default.nix` — `gpg-agent-ssh.nix`
- `users/deepwatrcreatur/hosts/nixos-lxc/nixos_lxc/default.nix` — `gpg-agent-ssh.nix`

### root user (4 hosts)
- `users/root/default.nix` — `gpg-cli.nix`
- `users/root/hosts/attic-cache/default.nix` — `gpg-cli.nix`
- `users/root/hosts/proxmox/default.nix` — `gpg-cli.nix`
- `users/root/hosts/nixos-lxc/nixos_lxc/default.nix` — `gpg-cli.nix`

Each replacement: remove GPG module import, add `git-ssh-signing.nix`
import and (for deepwatrcreatur) `ssh-agent.nix` import.

## Non-Goals

- Module creation (item 24)
- Module deletion (item 26)

## Validation

- `nix-instantiate --parse` on all modified host files
- eval at least one nixos and one darwin host confirms no gpg-agent

## Dependencies

- Item 24 must be merged first (or developed in the same branch)
