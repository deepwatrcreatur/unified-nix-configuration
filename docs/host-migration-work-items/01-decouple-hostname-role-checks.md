# 01 Decouple Hostname Role Checks

Status: `in-progress`
Suggested branch: `feat/host-naming-cleanup`
Priority: `high`

## Goal

Eliminate hardcoded `config.networking.hostName == "attic-cache"` assertions so that nodes can host functional roles without requiring their machine hostname to match the role name.

## Why

- In `modules/common/nix-settings.nix`, cache server detection currently checks `config.networking.hostName or "" == "attic-cache"`. If the host is renamed to `emerald`, this check evaluates to `false`, breaking local cache substitution avoidance (causing circular substitution loops).
- In `lib/remote-builder.nix`, `canUse` checks `hostName != "attic-cache"`.
- Decoupling these via explicit module/aspect options (`myModules.caches.isCacheServer`) allows any host to assume the cache role purely by importing `den/aspects/attic-cache-core.nix`.

## Scope

1. Add `options.myModules.caches.isCacheServer` in `den/aspects/nix-caches.nix`.
2. Set `myModules.caches.isCacheServer = true;` in `den/aspects/attic-cache-core.nix`.
3. Update `modules/common/nix-settings.nix` to read `config.myModules.caches.isCacheServer`, falling back to `config.networking.hostName == "attic-cache"` for backward compatibility.
4. Update `lib/remote-builder.nix` to exclude known cache/builder hostnames (`attic-cache`, `emerald`).
5. Run flake checks to guarantee zero regressions across all configurations.

## Validation

- `nix build .#checks.x86_64-linux.inventory-consistency --no-link` succeeds.
- `nix build .#checks.x86_64-linux.module-loading-eval --no-link` succeeds.
- `nix eval .#nixosConfigurations.attic-cache.config.nix.settings.substituters` confirms local cache remains excluded on cache server.
- `nix eval .#nixosConfigurations.workstation.config.nix.settings.substituters` confirms local cache remains present on client nodes.
