---
title: Router Bootstrap Flow
---

## purpose
Capture the steps and tooling that a helper (human or agent) needs to install the minimal `router-bootstrap` output from a live ISO.

## repo layout
1. `modules/nixos/bootstrap/base.nix` defines the trimmed environment packages, users (stable SSH keys), network/SSH/snapper defaults, Limine bootloader, and the remote builder configuration.
2. `hosts/nixos/router-bootstrap/*` plus `den/aspects/bootstrap-base.nix`, `den/hosts/router-bootstrap/default.nix`, `den/inventory/hosts.nix`, and `lib/hosts.nix` wire the new host into the inventory/aspect system.

## install procedure
1. **Prep the live iso**
   - On the live USB shell, **mount `/dev/sda1` in `/mnt`** and clean `/nix/store` (`nix-collect-garbage -d`). The live store is a small tmpfs, so it must be emptied before copying large closures.
2. **Get the repo in place**
   - From workstation: `tar -C /home/deepwatrcreatur/flakes -czf /tmp/router-bootstrap-repo.tgz unified-nix-configuration`
   - `scp` that tarball to `root@10.10.10.39:/root/`, unpack it, and `git config --global --add safe.directory /root/unified-nix-configuration`.
3. **Build the closure once**
   - On a builder with a real store (attic-cache/workstation), run `nix build --no-link .#nixosConfigurations.router-bootstrap.config.system.build.toplevel` so the closure lives in `/nix/store`.
4. **Copy the closure**
   - Copy the closure to the live ISO via a temporary tarball or `nix copy --extra-experimental-features 'nix-command' --no-check-sigs --from file:///tmp/router-bootstrap-store /nix/store/...router-bootstrap...`.
5. **Install**
   - From the live ISO (still under UEFI/OVMF) run `nixos-install --root /mnt --no-root-password --flake path:/root/unified-nix-configuration#router-bootstrap`.
   - Limine installs properly only in UEFI mode; SeaBIOS will error.

## finish
1. Reboot the VM under UEFI so the installed generation boots.
2. Once SSH is back, run `nixos-rebuild switch --flake .#router` to transition to the full router profile.
3. Cleanup: remove `/tmp/router-bootstrap-store` on both the live ISO and builder hosts.

## troubleshooting
- Use `nix copy --from file:///tmp/router-bootstrap-store` when `/nix/store` is too small; avoid `NIX_STORE_DIR` overrides that break the cache prefix.
- If `nixos-install` fails inside the installer, confirm the closure exists and reinstall Limine via UEFI before switching firmware back.
