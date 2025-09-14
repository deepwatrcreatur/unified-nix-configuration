# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a unified multi-host Nix configuration repository that manages NixOS, nix-darwin (macOS), and Home Manager configurations across different machines. The flake uses a modular architecture with helper functions to reduce boilerplate.

## Build and Deployment Commands

### macOS (nix-darwin) - macminim4
```bash
# Standard rebuild (from host directory)
darwin-rebuild switch --flake ~/unified-nix-configuration/.#macminim4

# Using nh (preferred)
nh darwin switch
```

### NixOS Hosts
```bash
# Standard rebuild for homeserver
sudo nixos-rebuild switch --flake /path/to/repo#homeserver

# Using nh (where available)
nh os switch

# For LXC containers
nix --experimental-features 'nix-command flakes' run 'github:viperML/nh' -- os switch /path/to/repo
```

### Home Manager (standalone)
```bash
# For standalone home-manager configs
nh home switch /path/to/repo#homeConfigurations.username.activationPackage
```

## Architecture

### Core Structure
- `flake.nix`: Main entry point with helper functions for system builders
- `outputs/`: Individual host output definitions that use the helpers
- `hosts/`: Host-specific configurations organized by type
- `modules/`: Shared modules organized by platform (common, nix-darwin, nixos, home-manager)
- `users/`: User-specific Home Manager configurations

### Helper Functions (flake.nix:86-190)
- `mkDarwinSystem`: Standard nix-darwin system builder with Home Manager integration
- `mkNixosSystem`: Standard NixOS system builder with Home Manager integration
- `mkOmarchySystem`: Specialized NixOS builder for omarchy-nix integration
- `mkHomeConfig`: Standalone Home Manager configuration builder

### Host Categories
- **macOS**: `hosts/macminim4/` - Darwin configuration
- **NixOS**: `hosts/homeserver/`, `hosts/nixos/` - Standard NixOS hosts
- **LXC**: `hosts/nixos-lxc/` - Container-specific configurations
- **Infisical**: `hosts/infisical/` - Secrets management host

### Module Organization
- `modules/common/`: Cross-platform shared modules (packages, nix-settings, etc.)
- `modules/nix-darwin/`: macOS-specific modules (dock, finder, security)
- `modules/nixos/`: Linux-specific modules (networking, services)
- `modules/home-manager/`: User environment configuration (shells, tools, applications)

### User Configuration
User configs are organized under `users/{username}/` with host-specific overrides in `users/{username}/hosts/{hostname}/`. Each user has justfiles for common tasks.

## Common Development Patterns

### Adding a New Host
1. Create host directory under appropriate category (`hosts/nixos/`, `hosts/macminim4/`, etc.)
2. Add output configuration in `outputs/` using appropriate helper function
3. Add user-specific configuration in `users/{username}/hosts/{hostname}/`

### Module Dependencies
- System modules receive `inputs` and pure `nixpkgsLib`
- Home Manager modules receive `inputs` and `mac-app-util` for macOS app management
- SOPS-nix is integrated for secrets management across all configurations

### Justfile Integration
Each host/user combination has justfiles with common commands. The `just` command runner is available system-wide through `modules/common/just.nix`.

## Key Dependencies
- `mac-app-util`: macOS application management (line 20, 74)
- `sops-nix`: Secrets management across all platforms
- `nix-homebrew`: macOS package management integration
- `nh`: Modern Nix helper for rebuilds and maintenance
- `determinate`: Nix installer and system integration