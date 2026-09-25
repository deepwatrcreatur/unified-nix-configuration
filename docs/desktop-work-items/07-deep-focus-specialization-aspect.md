# 07 Deep-Focus Specialization Aspect

Status: `done`
Suggested branch: `feat/aspect-deep-focus`
Priority: `medium`

## Goal

Add a `deep-focus` bootloader specialization aspect (`den/aspects/deep-focus.nix`) that configures a distraction-free environment for concentrated development work.

## Why

Switching context for high-focus coding or architecture work is often disrupted by background notifications, chat popups, and unstructured windows. A dedicated boot specialization sets up an intentional, focused workspace at startup.

## Scope

1. Create `modules/nixos/specializations/deep-focus.nix`:
   - Specialization tag: `system.nixos.tags = [ "deep-focus" ];`.
   - Forces notification silence: enables Do-Not-Disturb on desktop notification daemons (`swaync`, `mako`, or GNOME/COSMIC notification centers).
   - Suppresses non-essential background daemons and update checks.
   - Sets up focused default desktop layout (arranging editor, terminal, and browser cleanly into designated workspaces).
2. Create `den/aspects/deep-focus.nix` and register in `den/aspects/default.nix`.
3. Provide option `options.myModules.specializations.deepFocus.enable` (default `false`).
4. Wire as an opt-in aspect available to workstation nodes.

## Validation

- `nix eval .#nixosConfigurations.phoenix.config.system.build.toplevel.drvPath` evaluates cleanly.
- When enabled on `phoenix`, `specialisation.deep-focus.configuration.system.nixos.tags` evaluates to `[ "deep-focus" ]`.
