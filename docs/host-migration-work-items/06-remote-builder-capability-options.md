# 06 Remote Builder Capability Options

Status: `done`
Suggested branch: `feat/remote-builder-capabilities`
Priority: `medium`

## Goal

Eliminate hardcoded static hostname arrays in `lib/remote-builder.nix` and `modules/common/nix-settings.nix`, replacing them with dynamic dendritic capability options.

## Why

Currently, `lib/remote-builder.nix` decides which machines can substitute builds or act as remote builders via static string lists:
```nix
nixosHosts = [ "homeserver" "router" "workstation" "phoenix" ];
cacheHosts = [ "attic-cache" "emerald" ];
```
And `modules/common/nix-settings.nix` still contains fallback checks:
```nix
|| (config.networking.hostName or "" == "attic-cache");
```
Whenever a node is renamed (e.g. `homeserver` -> `sapphire`, `router` -> `ruby`), or new nodes are added, `lib/remote-builder.nix` must be manually edited to prevent broken build routing or circular substitution loops.

## Scope

1. In `den/aspects/attic-client.nix`:
   - Set `options.myModules.builder.canUseRemoteBuilder = true;`.
2. In `den/aspects/attic-cache-core.nix`:
   - Set `options.myModules.caches.isCacheServer = true;`.
3. In `lib/remote-builder.nix`:
   - Refactor `canUse` and `canUseNixOS` to check module options or host facts instead of rigid string lists.
4. In `modules/common/nix-settings.nix`:
   - Fully decouple `isCacheServer` and `canUseRemoteBuilder` from hostname string matching.

## Validation

- `nix build .#checks.x86_64-linux.inventory-consistency --no-link` passes.
- `nix build .#checks.x86_64-linux.module-loading-eval --no-link` passes.
- `nix eval .#nixosConfigurations.emerald.config.nix.settings.substituters` confirms local cache remains excluded on cache server.
- `nix eval .#nixosConfigurations.phoenix.config.nix.settings.substituters` confirms local cache remains present on client nodes.
