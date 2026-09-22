# 11 Emerald Niri + Noctalia Workstation Stack

Status: `done`
Suggested branch: `feat/aspect-niri-noctalia`
Priority: `medium`

## Goal

Introduce the modern scrollable-tiling Wayland compositor **Niri** and the unified desktop shell **Noctalia v5** as discrete dendritic aspects, and compose them onto the `emerald` workstation in `den/inventory/hosts.nix`.

## Why

1. **Independent Desktop Identity**: `phoenix` runs COSMIC desktop. `emerald` should have a modern, distinct, and highly productive scroll-tiling environment without coupling either machine to a single global desktop environment.
2. **Lean Architecture**: Rather than stitching together 6+ distinct daemons (Waybar + SwayNC + Wofi + Swaylock + Wlsunset + SwayOSD), Noctalia v5 provides a unified, native GTK4/Rust desktop shell (bar, launcher, lockscreen, notification daemon, control center, night light, and OSD) with a lower memory footprint and zero Quickshell/KDE QML dependency overhead.
3. **Dynamic Theming**: Noctalia v5 provides native Material 3 (M3) wallpaper color extraction (`m3-tonal-spot`) that automatically propagates cohesive color schemes to Niri focus rings, GTK3/4, Foot/Kitty terminals, and Starship without requiring manual color coordination or heavy runtime scripts.

## Reference Implementations

- **Modern Niri + Noctalia v5 Reference**: [`niii-san/nixos-config`](https://github.com/niii-san/nixos-config) (`modules/home/window-managers/niri/default.nix`, `modules/home/noctalia/default.nix`, `flake.nix`).
- **Niri KDL Styling & Layer Rules Reference**: [`sensei/nixos`](https://codeberg.org/sensei/nixos) (`config/niri/config.desktop.kdl`, `config/niri/noctalia.kdl`).
- **Dendritic Multi-WM Packaging Reference**: [`nicolkrit999/nix`](https://github.com/nicolkrit999/nix) (`modules/nixos/programs/de-wm/niri/`, `modules/nixos/programs/shells/noctalia-main.nix`).

## Scope

1. **Flake Inputs**:
   - Add `niri` (`github:sodiboo/niri-flake`, following `nixpkgs`).
   - Add `noctalia` (`github:noctalia-dev/noctalia`, following `nixpkgs`).
2. **Dendritic Aspects in `den/aspects/`**:
   - `den/aspects/workstation-niri.nix`:
     - System-level Niri enablement (`programs.niri.enable = true;`).
     - Includes `xwayland-satellite` for X11 compatibility.
     - Configures Polkit, XDG desktop portals (`xdg-desktop-portal-gnome` / `xdg-desktop-portal-gtk`), and greetd/login manager.
     - Home Manager Niri settings: infinite horizontal scroll layout, spring-based animations, window rules, layer rules (`namespace="^noctalia-wallpaper.*"` and `namespace="^noctalia-backdrop.*"` with `place-within-backdrop = true;`, and notifications with `block-out-from = "screencast";`).
     - Keybindings invoking Noctalia v5 IPC (`noctalia msg panel-toggle launcher`, `noctalia msg session lock`, `noctalia msg panel-toggle control-center`, etc.).
   - `den/aspects/desktop-noctalia.nix`:
     - Home Manager module integration (`inputs.noctalia.homeModules.default`).
     - Declarative Noctalia v5 configuration (`programs.noctalia.settings`): floating glass bar, launcher, lockscreen, notification center, control center, nightlight, and M3 wallpaper-driven color scheme.
     - Spawns `noctalia` at Niri startup (`programs.niri.settings.spawn-at-startup = [ { command = [ "noctalia" ]; } ];`).
3. **Register Aspects**:
   - Register `"workstation-niri"` and `"desktop-noctalia"` in `den/aspects/default.nix`.
4. **Wire into `emerald` Inventory**:
   - Update `den/inventory/hosts.nix`: add `"workstation-niri"` and `"desktop-noctalia"` (along with `"workstation-desktop"`) to `emerald.aspectsList`.

## Validation

- `nix build .#checks.x86_64-linux.inventory-consistency --no-link` passes.
- `nix eval .#nixosConfigurations.emerald.config.system.build.toplevel.drvPath` evaluates successfully.
- `nix eval .#nixosConfigurations.emerald.config.programs.niri.enable` evaluates to `true`.
