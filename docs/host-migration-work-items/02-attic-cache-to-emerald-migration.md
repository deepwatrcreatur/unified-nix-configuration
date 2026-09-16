# 02 Attic Cache To Emerald Migration

Status: `ready`
Suggested branch: `feat/emerald-cache-migration`
Priority: `high`
Depends on: `01-decouple-hostname-role-checks`

## Goal

Migrate the Nix binary cache LXC/VM from functional hostname `attic-cache` to node identity `emerald`, establishing `attic-cache` as a DNS and SSH alias.

## Scope

1. In `lib/hosts.nix`:
   - Rename host entry `attic-cache` to `emerald`.
   - Add `aliases = [ "attic-cache" "cache" "nix-cache" ];`.
   - Update description.
2. In `den/inventory/hosts.nix`:
   - Rename host `attic-cache` to `emerald`.
   - Update `name = "emerald";` and `hostPath = ../hosts/emerald;`.
3. In `den/hosts/`:
   - Move `den/hosts/attic-cache/` to `den/hosts/emerald/`.
   - Update `name = "emerald"` in `den/hosts/emerald/default.nix`.
4. In `users/`:
   - Move `users/deepwatrcreatur/hosts/attic-cache` -> `users/deepwatrcreatur/hosts/emerald`.
   - Move `users/root/hosts/attic-cache` -> `users/root/hosts/emerald`.
5. In Agenix & Secrets:
   - Rename `ssh-keys/agenix-machine-identities/attic-cache.pub` to `emerald.pub`.
   - Update `secrets.nix` (`rootSshKeyHosts` and `hosts.emerald`).
   - Run `just rekey`.
6. Validate and open PR.

## Validation

- `nix build .#checks.x86_64-linux.inventory-consistency --no-link`
- `nix eval .#nixosConfigurations.emerald.config.system.build.toplevel.drvPath --raw`
- DNS zone checks confirm `attic-cache` CNAME points to `emerald`.
