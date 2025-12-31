# modules/home-manager/just.nix - Base Justfile with common commands
{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.just ];

  # Create justfile in home directory for auto-discovery by Just
  # Just only searches current directory and parents, not ~/.config/just
  home.file.".justfile".text = lib.mkBefore ''
    # Default command when 'just' is run without arguments
    default: help

    # Display help and available commands
    help:
        @printf "\nRun 'just -n <command>' to print what would be executed...\n\n"
        @just --list --unsorted
        @printf "\n...by running 'just <command>'.\n"
        @printf "This message is printed by 'just help' and just 'just'.\n"

    # Print nix flake inputs and outputs
    nix-io:
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
}