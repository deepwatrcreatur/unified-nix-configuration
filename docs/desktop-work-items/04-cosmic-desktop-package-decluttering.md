# 04 COSMIC Desktop Package Decluttering

Status: `done`
Suggested branch: `feat/cosmic-exclude-packages`
Priority: `medium`

## Goal

Declutter the COSMIC desktop environment by excluding redundant stock applications that are superseded by existing tools (e.g. Ghostty, Wezterm, Zed, VSCode).

## Why

COSMIC Desktop pulls in default applications (`cosmic-term`, `cosmic-store`, `cosmic-edit`, `cosmic-files`, `cosmic-player`) that duplicate dedicated applications already configured in the user's desktop profile. Excluding them reduces store clutter and avoids confusing duplicate file associations.

## Scope

1. In `modules/nixos/sessions/cosmic.nix`:
   - Add `environment.cosmic.excludePackages = with pkgs; [ cosmic-term cosmic-store cosmic-applibrary cosmic-edit cosmic-files cosmic-player ];`.
   - Add `services.desktopManager.cosmic.showExcludedPkgsWarning = false;`.
2. Ensure exclusion list can be customized or overridden if specific apps are desired.

## Validation

- `nix eval .#nixosConfigurations.phoenix.config.environment.cosmic.excludePackages` evaluates without errors.
- Flake checks succeed.
