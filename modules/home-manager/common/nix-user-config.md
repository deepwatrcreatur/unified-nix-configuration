# Nix User Configuration Module

This module manages `~/.config/nix/nix.conf` and the managed block in `/nix/var/determinate/netrc` for systems using Determinate Nix (where `nix.enable = false`).

## Purpose

On systems using Determinate Nix, the system-level `nix.settings` configuration is disabled. This module provides equivalent functionality at the user level through Home Manager.

## Default Configuration

By default, this module:
- Enables Attic cache at `http://cache-build-server:5001/cache-local`
- Falls back to `cache.nixos.org`
- Configures authentication via a managed Determinate Nix netrc block
- Enables common experimental features (flakes, nix-command, etc.)

## Per-Host Customization

To customize for a specific host, add to your user's host configuration:

```nix
# users/username/hosts/hostname/default.nix
{
  services.nix-user-config = {
    # Disable if you want to manage nix.conf manually
    enable = true;

    # Override substituters
    substituters = [
      "http://my-cache:5001/cache"
      "https://cache.nixos.org"
    ];

    # Override trusted keys
    trustedPublicKeys = [
      "my-cache:abc123..."
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    # Disable netrc authentication
    netrcMachine = null;

    # Or add explicit managed netrc entries
    netrcEntries = [
      {
        machine = "cache.example.internal";
        login = "token";
        passwordPath = "${config.home.homeDirectory}/.config/nix/cache-token";
      }
    ];

    # Append a preformatted netrc snippet verbatim
    netrcSnippetPaths = [
      "${config.home.homeDirectory}/.config/nix/nix-ci-netrc"
    ];
  };
}
```

## System vs User Configuration

- **NixOS systems**: Use `modules/common/nix-settings.nix` (system-level)
- **Determinate Nix systems**: Use this module (user-level via Home Manager)
- **LXC containers**: Use `modules/nixos/nix-settings-lxc.nix` (system-level)

## Files Managed

- `~/.config/nix/nix.conf` - Nix configuration (substituters, keys, features)
- `/nix/var/determinate/netrc` - managed netrc block for private cache authentication

## Integration with Attic

This module works alongside `modules/home-manager/common/attic-client.nix`:
- This module: Configures Nix to **use** the cache during builds
- attic-client: Provides tools to **push** to the cache manually

## Proxmox Root Pattern

The `proxmox-root` Home Manager output uses this module to prefer the local Attic cache and fall back to `cache.nix-ci.com`.

- Attic auth is modeled as a managed `netrcEntries` stanza backed by the root attic token.
- NixCI auth is modeled as a preformatted snippet in `netrcSnippetPaths`, which keeps the `login` and `password` pair together.
- The matching Proxmox bootstrap playbook is responsible for seeding those files before the first `home-manager switch`.
