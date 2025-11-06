# Unified Nix Configuration Repository

This repository contains a unified Nix configuration for managing multiple systems, including NixOS, macOS, and Linux distributions. It uses Nix Flakes to ensure reproducible builds and deployments.

## Overview

The primary goal of this repository is to provide a single source of truth for system and user configurations across various machines. This includes:

-   System-level settings (e.g., networking, services)
-   User-specific configurations (e.g., shell environment, applications)
-   Secret management using `sops-nix`

## Technologies

-   **Nix:** A powerful package manager and system configuration tool.
-   **NixOS:** A Linux distribution built on top of the Nix package manager.
-   **home-manager:** A tool to manage user-level dotfiles and packages.
-   **Nix Flakes:** A new feature in Nix that improves reproducibility and composability.
-   **sops-nix:** A tool for managing secrets in Nix configurations.

## Directory Structure

-   `hosts/`: Contains the main configuration for each individual host. Each host has a dedicated directory with its specific NixOS or home-manager configuration.
-   `modules/`: Contains reusable Nix modules that are shared across different hosts. This includes common packages, system settings, and user configurations.
-   `users/`: Contains user-specific configurations, such as dotfiles, packages, and services.
-   `secrets/`: Contains encrypted secret files managed by `sops`.

## Getting Started

To apply the configuration for a specific host, you can use the following command from the root of the repository:

```bash
nixos-rebuild switch --flake .#<hostname>
```

Replace `<hostname>` with the name of the host you want to configure (e.g., `homeserver`, `workstation`).
