# 06 Decompose Workstation Profile into Granular Aspects

Status: `done`
Suggested branch: `feat/aspect-workstation-decomposition`
Priority: `high`

## Goal

Decompose the monolithic `hosts/nixos/workstation/profile.nix` (which is currently imported by `den/aspects/workstation-desktop.nix`) into granular, single-responsibility aspects in `den/aspects/`.

## Why

Currently, `hosts/nixos/workstation/profile.nix` acts as an entangled monolith:
- Hardcodes a specific physical printer: `../../../modules/nixos/printers/phoenix-hp-m477.nix`.
- Declares `host.desktop.environment = "gnome"`, yet directly imports `../../../modules/nixos/sessions/cosmic.nix`.
- Bundles Btrfs Snapper, OpenLogi, HP print/scan, Snapd, and Wezterm together into all workstation-class nodes.

This prevents new desktop machines (such as a laptop leaf, a clean GNOME-only setup, or a VM) from using workstation features without inheriting Phoenix-specific hardware or unwanted desktop environments.

## Scope

1. Create discrete aspects in `den/aspects/`:
   - `den/aspects/desktop-cosmic.nix`: Encapsulates COSMIC desktop session, greetd launcher, and package exclusions.
   - `den/aspects/desktop-gnome.nix`: Encapsulates native GNOME desktop configuration.
   - `den/aspects/hardware-printer-phoenix-m477.nix`: Encapsulates the specific HP PageWide Pro 477dn MFP printer setup.
   - `den/aspects/btrfs-snapper.nix`: Encapsulates Snapper configuration and CLI helper scripts.
2. Refactor `den/aspects/workstation-desktop.nix` to only provide common baseline workstation concerns (sound, base desktop utilities, common fonts/tools).
3. Update `den/inventory/hosts.nix` for `phoenix` and `workstation` to explicitly compose the new granular aspects (`"workstation-desktop"`, `"desktop-cosmic"`, `"hardware-printer-phoenix-m477"`, `"btrfs-snapper"`).
4. Register all new aspects in `den/aspects/default.nix`.

## Validation

- `nix build .#checks.x86_64-linux.inventory-consistency --no-link` passes.
- `nix eval .#nixosConfigurations.phoenix.config.system.build.toplevel.drvPath` evaluates successfully.
- `nix eval .#nixosConfigurations.workstation.config.system.build.toplevel.drvPath` evaluates successfully.
