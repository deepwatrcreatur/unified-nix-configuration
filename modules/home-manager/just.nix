# modules/home-manager/just.nix - Base Justfile with common commands
{ pkgs, lib, ... }:
{
  programs.just = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      # Default command when 'just' is run without arguments
      default = "help";

      # Display help
      help = {
        docs = "Display help and available commands";
        command = ''
          @printf "\nRun 'just -n <command>' to print what would be executed...\n\n"
          @just --list --unsorted
          @printf "\n...by running 'just <command>'.\n"
          @printf "This message is printed by 'just help' and just 'just'.\n"
        '';
      };

      "-n" = {
        docs = "Print what would be executed without running";
        private = true;
      };

      # Common Nix operations
      [group "nix"]
      nix = {
        docs = "Nix flake operations";
      };

      "nix:io" = {
        docs = "Print nix flake inputs and outputs";
        command = "nix flake metadata";
      };

      "nix:update" = {
        docs = "Update nix flake lock file";
        command = "nix flake update";
      };

      "nix:fmt" = {
        docs = "Format Nix files";
        command = "nix fmt";
      };

      "nix:check" = {
        docs = "Check nix flake configuration";
        command = "nix flake check";
      };

      info = {
        docs = "Show system information";
        command = "nix flake metadata && nix path-info nixpkgs";
      };

      test = {
        docs = "Run tests";
        command = "nix flake check";
      };

      "test:build" = {
        docs = "Test build process";
        command = "nix build --dry-run";
      };

      clean = {
        docs = "Remove build output links";
        command = "rm -f ./result";
      };

      "clean:all" = {
        docs = "Full cleanup including garbage collection";
        command = "rm -f ./result && nix store gc";
      };

      # Quick aliases
      fmt = {
        docs = "Format Nix files";
        command = "nix fmt";
      };

      check = {
        docs = "Check flake configuration";
        command = "nix flake check";
      };
    };
  };
}