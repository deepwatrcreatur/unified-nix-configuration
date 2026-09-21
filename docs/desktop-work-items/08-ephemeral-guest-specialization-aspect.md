# 08 Ephemeral Guest Specialization Aspect

Status: `ready`
Suggested branch: `feat/aspect-guest`
Priority: `medium`

## Goal

Add a disposable `guest` account specialization aspect (`den/aspects/guest.nix`) providing a safe, ephemeral visitor environment on physical workstations.

## Why

When lending a workstation to family, guests, or visitors, personal credentials, SSH keys, browser sessions, and internal homelab services must be protected from accidental exposure without creating a permanent account or requiring manual cleanup.

## Scope

1. Create `modules/nixos/specializations/guest.nix`:
   - Specialization tag: `system.nixos.tags = [ "guest" ];`.
   - Ephemeral `/home/guest` backed by `tmpfs` (e.g. `size=25%`, wiped completely on reboot with zero disk wear).
   - Mesh isolation: iptables/nftables firewall rules blocking access to Tailscale interface and the CGNAT subnet (`100.64.0.0/10`) for the guest UID (`2000`).
   - Resource throttling via `systemd.slices."user-2000"` (memory maximum and lower CPU weight).
   - Hardened browser policies (disables telemetry, first-run wizards, and pocket).
   - Clean autologin into a lightweight desktop session with a prominent warning that data is cleared on reboot.
2. Create `den/aspects/guest.nix` and register in `den/aspects/default.nix`.
3. Provide option `options.myModules.specializations.guest.enable` (default `false`).

## Validation

- `nix eval .#nixosConfigurations.phoenix.config.system.build.toplevel.drvPath` evaluates cleanly.
- When enabled on `phoenix`, `specialisation.guest.configuration.users.users.guest.uid` evaluates to `2000`.
