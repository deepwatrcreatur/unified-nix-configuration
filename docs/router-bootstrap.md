## Router Bootstrap Overview

- **Host definition:** `router-bootstrap` is described in `hosts/nixos/router-bootstrap/configuration.nix`, with guest hardware in `hosts/nixos/router-bootstrap/hardware-configuration.nix`. The `den` aspect tree wires it under `den/hosts/router-bootstrap/default.nix` and registers the new host in `den/inventory/hosts.nix` and `lib/hosts.nix`.
- **Bootstrap base module:** `modules/nixos/bootstrap/base.nix` provides a minimal system package set (`attic-client`, `bashInteractive`, `btrfs-progs`, `curl`, `git`, `just`, `snapper`, `tmux`), NetworkManager/DHCP, root/deepwatrcreatur SSH keys, Limine+EFI bootloader, snapper, and the built-in remote builder configuration (attic-cache machine with SSH key and `StrictHostKeyChecking accept-new`).
- **Workflow to install:** 
  1. From `workstation`, package the repo with `tar -C /home/deepwatrcreatur/flakes -czf /tmp/router-bootstrap-repo.tgz unified-nix-configuration` and `scp` it to `root@10.10.10.39:/root/`.
  2. On the live USB (UEFI/OVMF), unpack the tarball, set `git config --global --add safe.directory /root/unified-nix-configuration`, and clean `/nix/store` (`nix-collect-garbage -d`).
  3. Build `router-bootstrap` on a full builder (attic-cache) with `nix build --no-link .#nixosConfigurations.router-bootstrap.config.system.build.toplevel`, copy the resulting `/nix/store/...router-bootstrap...` via a temporary cache directory (e.g., `nix copy --to file:///tmp/router-bootstrap-store ...`), and transfer that cache to the live ISO.
  4. Run `nixos-install --root /mnt --no-root-password --flake path:/root/unified-nix-configuration#router-bootstrap`; the installed system uses Limine on EFI, so the VM must boot under OVMF.
  5. After install, reboot under OVMF, verify SSH, and then transition to `. #router` once the bootstrap system is online.
- **Key notes:** keep OVMF enabled for this output, because Limine assumes EFI; the bootstrap package set uses `lib.mkDefault` so other modules can extend it; the system delivers caches/builders via `programs.ssh.extraConfig` and the `nix.buildMachines` list.
