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
### Module Organization
- `modules/common/`: Cross-platform shared modules (packages, nix-settings, etc.) - imported by all hosts
- `modules/nix-darwin/`: macOS-specific modules (dock, finder, security) - auto-imported only by Darwin hosts via modules/nix-darwin/default.nix
- `modules/nixos/`: Linux-specific modules (networking, services) - imported by NixOS hosts
- `modules/home-manager/`: User environment configuration (shells, tools, applications) - imported by home-manager configurations

The auto-import system in `modules/nix-darwin/default.nix` automatically loads all `.nix` files from `modules/nix-darwin/common/`, providing clean separation without conditional logic.

### User Configuration
User configs are organized under `users/{username}/` with host-specific overrides in `users/{username}/hosts/{hostname}/`. Each user has justfiles for common tasks.

## Common Development Patterns

### Adding a New Host
1. Create host directory under appropriate category (`hosts/nixos/`, `hosts/macminim4/`, etc.)
2. Add output configuration in `outputs/` using appropriate helper function
3. Add user-specific configuration in `users/{username}/hosts/{hostname}/`

### Auto-Import Pattern
The repository uses an intelligent auto-import system to maintain clean separation between platforms:

**Darwin modules** (`modules/nix-darwin/`): 
- Automatically imports all `.nix` files from `modules/nix-darwin/common/`
- Explicitly imports specific modules like `system-limits.nix`
- Only loaded for Darwin hosts, ensuring macOS-specific settings don't affect NixOS

**NixOS modules** (`modules/nixos/`):
- Imported explicitly by NixOS host configurations
- Contains Linux-specific services and settings

This pattern eliminates the need for conditional logic within modules and prevents platform-specific options from causing build failures on incompatible systems.

### Platform-Specific Settings Example
The `max-open-files` nix setting is a perfect example of why this architecture is important:
- This setting only exists in nix-darwin, not NixOS
- By placing it in `modules/nix-darwin/system-limits.nix`, it only affects Darwin hosts
- NixOS hosts never see this setting, preventing build failures
- The alternative approach (conditional logic in common modules) is error-prone and harder to maintain

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

## Common Issues and Solutions

### Build Failures Due to Platform-Specific Options
**Problem**: Error like `error: unknown setting 'max-open-files'` on NixOS
**Cause**: Darwin-specific nix settings being applied to NixOS hosts
**Solution**: Move platform-specific settings to appropriate module directories:
- Darwin-only settings → `modules/nix-darwin/`
- NixOS-only settings → `modules/nixos/`
- Common settings → `modules/common/`

### Module Import Issues
**Problem**: Module not being loaded or applied
**Check**: 
- For Darwin: Check `modules/nix-darwin/default.nix` auto-import logic
- For NixOS: Verify explicit import in host configuration
- For common: Ensure module is in `modules/common/` and properly structured

### Cache Authentication Errors
**Problem**: `HTTP error 401` from cache servers
**Solution**: Usually harmless - occurs when cache token isn't available, falls back to public caches

### Commit without signing
**Problem**: git commit opens password dialog that is difficult to handle in TUI
**Solution**: use --no-gpg-sign option

## Agent Instructions
### Shell Environment
- **Default shell is Fish**: Use Fish shell syntax for all commands to ensure compatibility with coding agents
- **Avoid Nushell**: While Nushell is configured, Fish is set as default to prevent agent compatibility issues
### Multi-Host Configuration Awareness
- **Always check hostname first**: Start by running `hostname` to identify which host you're working on
- **Host-specific commands**: Use appropriate commands based on the host type:
  - **NixOS hosts** (homeserver, workstation, etc.): Use `sudo nixos-rebuild` commands, account for non-FHS compliance
  - **Darwin hosts** (macminim4): Use `darwin-rebuild` commands, respect macOS peculiarities
  - **LXC containers**: May require special handling for container-specific rebuilds
### Host Detection Examples
```bash
# Check which host you're on
hostname
# Then use appropriate rebuild commands:
# For NixOS: sudo nixos-rebuild switch --flake .#hostname
# For Darwin: darwin-rebuild switch --flake .#hostname
```
