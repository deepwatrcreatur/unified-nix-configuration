# modules/home-manager/common/just.nix - Unified Just module with auto-platform detection
{
  config,
  pkgs,
  lib,
  hostName ? config.home.username,
  platform ? null,
  hostSpecificJustfile ? null,
  ...
}:

let
  # Auto-detect platform if not specified
  detectedPlatform =
    if pkgs.stdenv.isDarwin then
      "darwin"
    else if pkgs.stdenv.isLinux then
      "nixos"
    else
      "unknown";
  currentPlatform = platform;
  # Base justfile content (common commands)
  baseJustfile = ''
    # Default command when 'just' is run without arguments
    default: help

    # Display help and available commands
    help:
        @printf "\nRun 'just -n <command>' to print what would be executed...\n\n"
        @just --list --unsorted
        @printf "\n...by running 'just <command>'.\n"
        @printf "This message is printed by 'just help' and just 'just'.\n"

    # Print nix flake inputs and outputs
    nix-info:
        nix flake metadata

    # Update nix flake lock file
    nix-update:
        nix flake update

    # Format Nix files
    nix-fmt:
        nix fmt

    # Check nix flake configuration
    nix-check:
        nix flake check

    # Show system information
    info:
        nix flake metadata && nix path-info nixpkgs

    # Run tests
    test:
        nix flake check

    # Test build process
    test-build:
        nix build --dry-run

    # Remove build output links
    clean:
        rm -f ./result

    # Full cleanup including garbage collection
    clean-all:
        rm -f ./result && nix store gc

    # Format Nix files (alias)
    fmt: nix-fmt

    # Check flake configuration (alias)
    check: nix-check
  '';

  # Platform-specific extensions
  darwinExtension = ''
    # macOS Commands
    # ==============

    # Update macOS system using darwin-rebuild
    update:
        ulimit -n 65536; sudo /nix/var/nix/profiles/system/sw/bin/darwin-rebuild switch --flake $NH_FLAKE#${hostName}

    # Update macOS system using nh helper
    nh-update:
        nh darwin switch

    # Build macOS system without switching
    build-darwin:
        ulimit -n 65536; sudo /nix/var/nix/profiles/system/sw/bin/darwin-rebuild build --flake $NH_FLAKE#${hostName}

    # Test macOS configuration
    test-darwin:
        ulimit -n 65536; sudo /nix/var/nix/profiles/system/sw/bin/darwin-rebuild test --flake $NH_FLAKE#${hostName}

    # Show macOS version
    darwin-version:
        sw_vers

    # Show installed Nix apps
    darwin-apps:
        ls /nix/var/nix/profiles/per-user/*/profile/Applications

    # Garbage collect Nix store
    system-gc:
        nix-collect-garbage -d

    # Optimize Nix store
    system-optimize:
        nix-store --optimise

    # Reload macOS launch services
    macos-reload:
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

    # Clean macOS caches
    macos-clean:
        sudo rm -rf /Library/Caches/* && rm -rf ~/Library/Caches/*

    # Quick switch (alias for update)
    switch: update
  '';

  nixosExtension = ''
    # NixOS Commands
    # ==============

    # Update NixOS system using nixos-rebuild
    update:
        /run/current-system/sw/bin/sudo nixos-rebuild switch --flake $NH_FLAKE#${hostName}

    # Update NixOS system using nh helper
    # Note: nh invokes sudo internally; ensure /run/current-system/sw/bin is first in PATH
    nh-update:
        PATH="/run/current-system/sw/bin:$PATH" nh os switch

    # Build NixOS system without switching
    build-nixos:
        /run/current-system/sw/bin/sudo nixos-rebuild build --flake $NH_FLAKE#${hostName}

    # Test NixOS configuration
    test-nixos:
        /run/current-system/sw/bin/sudo nixos-rebuild test --flake $NH_FLAKE#${hostName}

    # Show NixOS version
    nixos-version:
        nixos-version

    # Search NixOS options
    nixos-search query:
        nixos-option {{query}} 2>/dev/null || echo "Option not found. Try: man configuration.nix"

    # Garbage collect Nix store
    system-gc:
        /run/current-system/sw/bin/sudo nix-collect-garbage --delete-old

    # Optimize Nix store
    system-optimize:
        /run/current-system/sw/bin/sudo nix-store --optimise
      
    # Show available memory
    memory-stats:
        free -h
      
    # Show disk usage
    disk-usage:
        df -h
      
    # Quick switch (alias for update)
    switch: update
      
    # Quick system info
    system-info:
        uname -a
        nixos-version
  '';

  # Combine base with platform-specific extension
  fullJustfile =
    baseJustfile
    + (
      if currentPlatform == "darwin" then
        darwinExtension
      else if currentPlatform == "nixos" then
        nixosExtension
      else
        ""
    );

in
{
  home.packages = [ pkgs.just ];

  # Create justfile in home directory
  # Use host-specific justfile if provided, otherwise use generated one
  home.file.".justfile".text =
    if hostSpecificJustfile != null then hostSpecificJustfile else fullJustfile;
}
