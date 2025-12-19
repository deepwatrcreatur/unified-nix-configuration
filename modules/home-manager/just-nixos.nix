# modules/home-manager/just-nixos.nix - NixOS-specific Justfile commands
{ pkgs, lib, config, ... }:
let
  hostname = config.networking.hostName;
in
{
  programs.just.settings = {
    # NixOS-specific commands
    [group "nixos"]
    nixos = {
      docs = "NixOS system operations";
    };

    # Your preserved recipes with important features
    update = {
      docs = "Update NixOS system using nixos-rebuild";
      command = "/run/wrappers/bin/sudo nixos-rebuild switch --flake $NH_FLAKE#{{hostname}}";
    };

    "nh-update" = {
      docs = "Update NixOS system using nh helper";
      command = "nh os switch";
    };

    # Additional NixOS commands
    "build:nixos" = {
      docs = "Build NixOS system without switching";
      command = "/run/wrappers/bin/sudo nixos-rebuild build --flake $NH_FLAKE#{{hostname}}";
    };

    "test:nixos" = {
      docs = "Test NixOS configuration";
      command = "/run/wrappers/bin/sudo nixos-rebuild test --flake $NH_FLAKE#{{hostname}}";
    };

    # NixOS-specific helpers
    "nixos:version" = {
      docs = "Show NixOS version";
      command = "cat /etc/nixos-version";
    };

    "nixos:options" = {
      docs = "Show available NixOS options";
      command = "nixos-option";
    };

    "nixos:search" = {
      docs = "Search NixOS options";
      args = ["query"];
      command = "man configuration.nix | grep -i {{query}}";
    };

    # System management
    "system:gc" = {
      docs = "Garbage collect Nix store";
      command = "/run/wrappers/bin/sudo nix-collect-garbage -d";
    };

    "system:optimize" = {
      docs = "Optimize Nix store";
      command = "/run/wrappers/bin/sudo nix-store --optimise";
    };

    # Quick aliases
    switch = {
      docs = "Quick switch (alias for update)";
      command = "just update";
    };

    test = {
      docs = "Quick test (alias for test:nixos)";
      command = "just test:nixos";
    };
  };
}