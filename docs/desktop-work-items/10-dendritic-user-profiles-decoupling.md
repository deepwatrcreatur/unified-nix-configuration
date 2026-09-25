# 10 Dendritic User Profiles Decoupling

Status: `done`
Suggested branch: `feat/aspect-user-profiles`
Priority: `medium`

## Goal

Decouple user Home Manager profiles from rigid host-named directories (such as `users/deepwatrcreatur/hosts/workstation` and `users/deepwatrcreatur/hosts/router`) into composable user-level aspects.

## Why

In `den/hosts/phoenix/default.nix`, the primary user imports are currently wired as:
```nix
primaryUserImports = [
  inputs.nix-whitesur-config.homeManagerModules.default
  ../../../users/deepwatrcreatur/hosts/workstation
];
```
Because user configs were historically coupled to functional host directory names, `phoenix` is forced to import the `workstation` folder. As the repository transitions from functional host names (`workstation`, `attic-cache`, `router`) to node identities (`phoenix`, `emerald`, `ruby`), user profiles should be assembled from reusable persona aspects (e.g. developer environment, desktop GUI themes, CLI shells) rather than one directory per physical machine.

## Scope

1. Create reusable user aspects under `den/aspects/` or `users/deepwatrcreatur/aspects/`:
   - `user-developer`: Shell aliases, git tools, developer CLI utilities.
   - `user-desktop-whitesur`: WhiteSur theme, desktop wallpaper styling, and GUI bindings.
   - `user-server`: Minimal headless terminal configuration for router and server nodes.
2. Allow host leaves in `den/hosts/` to compose user aspects declaratively via `primaryUserImports` or den aspect composition.
3. Eliminate references to legacy host directories like `users/deepwatrcreatur/hosts/workstation` across `phoenix` and other node-identity leaves.

## Validation

- `nix build .#checks.x86_64-linux.inventory-consistency --no-link` succeeds.
- Evaluation of `phoenix` and `workstation` Home Manager environments matches existing packages and dotfiles with zero regression.
