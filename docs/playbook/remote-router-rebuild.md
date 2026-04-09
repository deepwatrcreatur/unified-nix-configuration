# Procedure: Remote Router Rebuild and Switch

**Context**: Rebuilding the router from a different machine (e.g. desktop) and
deploying changes remotely.

## Pre-Requisites

- SSH access to `10.10.10.1` (Production) or `192.168.100.100` (Management).
- `root-ssh-key` available in the local environment or on the target.

## Steps

1. **Build Locally**:
   ```bash
   nix build .#nixosConfigurations.router.config.system.build.toplevel --no-link
   ```
2. **Handle Cache Issues**: If `attic-cache` is unreachable, bypass it:
   ```bash
   nix build .#nixosConfigurations.router.config.system.build.toplevel --option substituters https://cache.nixos.org
   ```
3. **Copy to Target**:
   ```bash
   nix-copy-closure --to 10.10.10.1 /nix/store/<hash>-nixos-system-router-...
   ```
4. **Activate**:
   ```bash
   ssh 10.10.10.1 "sudo nix-env -p /nix/var/nix/profiles/system --set /nix/store/<hash> && sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch"
   ```

## Troubleshooting

- **Broken Sudo**: If `/run/current-system/sw/bin/sudo` is broken, use the wrapper: `/run/wrappers/bin/sudo`.
- **Wrong IP**: If a device lands on a wrong dynamic IP, check Technitium logs:
  `sudo grep leased /var/lib/technitium-dns-server/logs/$(date +%Y-%m-%d).log`.
- **Stale Leases**: Force renewal by removing active lease via Technitium API if reservation was just added.
