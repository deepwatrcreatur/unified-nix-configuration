# flake-parts/users/deepwatrcreatur.nix
{ inputs, ... }:
{
  #perSystem = { config, pkgs, ... }: {
  #  # Standalone Home Manager config (optional, for non-NixOS/darwin)
  #  homeConfigurations."deepwatrcreatur@pve-strix" = inputs.home-manager.lib.homeManagerConfiguration {
  #    pkgs = pkgs;
  #    extraSpecialArgs = { };
  #    modules = [
  #      ./../../users/deepwatrcreatur/common.nix
  #      ./../../users/deepwatrcreatur/hosts/pve-strix.nix
  #    ];
  #  };
  #};

  # Home Manager as a module for NixOS/darwin hosts
  flake = {
  };
}

