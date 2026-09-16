# 03 Homeserver To Sapphire Migration

Status: `ready`
Suggested branch: `feat/sapphire-homeserver-migration`
Priority: `medium`
Depends on: `01-decouple-hostname-role-checks`

## Goal

Migrate `homeserver` LXC/VM to node identity `sapphire`, establishing `homeserver` and `semaphore` as DNS and SSH aliases.

## Scope

1. In `lib/hosts.nix`:
   - Rename `homeserver` -> `sapphire`.
   - Add `aliases = [ "homeserver" "semaphore" ];`.
2. In `den/inventory/hosts.nix`:
   - Rename `homeserver` -> `sapphire`.
   - Update `hostPath = ../hosts/sapphire;`.
3. In `den/hosts/`:
   - Move `den/hosts/homeserver/` -> `den/hosts/sapphire/`.
4. In `users/`:
   - Move user host configs from `homeserver` to `sapphire`.
5. In Agenix & Secrets:
   - Rename `ssh-keys/agenix-machine-identities/homeserver.pub` to `sapphire.pub`.
   - Update `secrets.nix` and run `just rekey`.
6. Validate and open PR.

## Validation

- `nix build .#checks.x86_64-linux.inventory-consistency --no-link`
- `nix eval .#nixosConfigurations.sapphire.config.system.build.toplevel.drvPath --raw`
