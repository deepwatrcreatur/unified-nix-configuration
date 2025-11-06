# Claude's Guide to the Unified Nix Configuration

Hello! This is a guide to help you understand and work with this Nix configuration repository.

## Repository Purpose

This repository uses Nix to manage system and user configurations for multiple machines (NixOS, macOS). It's built with Nix Flakes for reproducibility.

## Key Technologies

-   **Nix/NixOS:** For system and package management.
-   **home-manager:** For user-specific dotfiles and packages.
-   **Nix Flakes:** For reproducible builds.
-   **sops-nix:** For managing secrets.

## How It's Organized

-   `flake.nix`: The main entry point.
-   `hosts/`: Configurations for each specific machine (e.g., `homeserver`, `macminim4`).
-   `modules/`: Shared and reusable configuration modules.
-   `users/`: User-specific settings.
-   `secrets/`: Encrypted secrets.

## Common Tasks

### Applying Configurations

-   **NixOS:** `sudo nixos-rebuild switch --flake .#<hostname>`
-   **macOS:** `darwin-rebuild switch --flake .#<hostname>`

Replace `<hostname>` with the target machine's name.

### Adding a new package to a system

1.  Find the correct host configuration file in `hosts/`.
2.  Add the package to the `environment.systemPackages` list.
3.  Rebuild the system configuration using the commands above.

### A Note on Secrets

Secrets are managed with `sops-nix`. To add or edit a secret, you'll need to use the `sops` CLI tool. The secrets are encrypted and safe to commit.
