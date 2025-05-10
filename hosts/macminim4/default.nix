{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/system/packages.nix 
  ];

  nix.enable = false; # Required for Determinate Nix Installer

  programs.fish.enable = true;

  services.tailscale.enable = true;

  users.users.deepwatrcreatur = {
    name = "deepwatrcreatur";
    home = "/Users/deepwatrcreatur";
  };

  system.stateVersion = 4;
}

