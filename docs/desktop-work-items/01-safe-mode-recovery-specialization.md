# 01 Safe-Mode Recovery Specialization Aspect

Status: `ready`
Suggested branch: `feat/aspect-safe-mode`
Priority: `high`

## Goal

Add a dedicated emergency recovery specialization aspect (`den/aspects/safe-mode.nix`) that provides an alternative bootloader entry (`safemode-tty`) in systemd-boot / GRUB for quick recovery when Wayland compositors (like COSMIC) or display managers crash, hang, or fail to start.

## Why

Bleeding-edge desktop releases (such as COSMIC desktop from unstable) can occasionally introduce crash loops, black screens, or broken session states. When this occurs, recovering via a VT console or emergency shell is cumbersome. A dedicated `safe-mode` bootloader entry provides an instant, dependable fallback.

## Scope

1. Create `den/aspects/safe-mode.nix` (or `modules/nixos/specializations/safe-mode.nix` + aspect wrapper):
   - Define `specialisation.safemode.configuration = { ... }`.
   - Add `system.nixos.tags = [ "safemode-tty" ];`.
   - Disable complex Wayland compositors and display managers (`services.greetd.enable = lib.mkForce false;`, `services.desktopManager.cosmic.enable = lib.mkForce false;`, etc.).
   - Enable minimal X11 IceWM (`services.xserver.windowManager.icewm.enable = lib.mkForce true;` with `services.xserver.displayManager.startx.enable = lib.mkForce true;`).
   - Force standard shell (`bash`), standard terminal (`xterm`), and basic editor (`nano`/`vim`).
   - Provide an emergency survival toolkit (`btrfs-progs`, `parted`, `ncdu`, `mc`, `htop`, `killall`, `curl`).
2. Wire `safe-mode` into the workstation desktop aspect or host profile as an opt-in aspect.
3. Validate evaluation on `phoenix` and `emerald`.

## Validation

- `nix eval .#nixosConfigurations.phoenix.config.specialisation.safemode.configuration.system.nixos.tags` evaluates to `[ "safemode-tty" ]`.
- `nix eval .#nixosConfigurations.phoenix.config.system.build.toplevel.drvPath` evaluates successfully.
