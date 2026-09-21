# Desktop and Dendritic Enhancements Work Queue

Start here if you are an agent picking up work from this queue.

## Queue Scope

This folder contains focused, PR-sized work items for desktop, audio, snapshot ergonomics, and dendritic specialization aspects inspired by proven patterns from [`nicolkrit999/nix`](https://github.com/nicolkrit999/nix).

## Onboarding Rules

1. **Check Claiming State**: Inspect [`README.md`](./README.md) and the item's header to ensure it is marked `ready`. Do not claim items already marked `in-progress` or `done`.
2. **One Item Per Branch**: Work in an isolated branch/worktree (e.g., `feat/<name>`) branched from `main`.
3. **Desktop Identity Rules**: 
   - `phoenix` and `emerald` are fixed desktop systems.
   - Do **NOT** enable `secure-travel` on `phoenix` or `emerald`. The module must exist in the repository for future mobile/laptop nodes while remaining dormant on desktops.
4. **Validation First**: Every item must validate with:
   - `nix flake check` or targeted eval: `nix eval .#nixosConfigurations.phoenix.config.system.build.toplevel.drvPath`
   - Zero evaluation regressions across existing hosts.
5. **Update State**: When claiming an item, mark its status as `in-progress`. When merged, mark it `done`.
