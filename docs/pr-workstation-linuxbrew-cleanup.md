## Summary

Extract the Linuxbrew/Homebrew compatibility activation from `hosts/nixos/workstation/default.nix` into the existing reusable `modules/activation-scripts/linux/linuxbrew-system.nix` module.

## Why

The workstation host file should stay focused on host-specific configuration. The Linuxbrew compatibility symlink setup is system-level plumbing and belongs with the Linuxbrew activation module, where it can be reused by other hosts.

## Changes

- remove inline `system.activationScripts.homebrewCompat` from workstation `default.nix`
- extend `linuxbrew-system.nix` to also create the absolute `/bin` and `/usr/bin` compatibility links Homebrew expects
- keep the workstation host config limited to enabling the module

## Notes

This is a cleanup/refactor PR only. It should not change intended behavior; it just moves Linuxbrew compatibility setup to the module that already owns Linuxbrew system preparation.
