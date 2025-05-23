{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/system/packages.nix
    ../../modules/nix-darwin/nix-mount.nix 
  ];

  nix.enable = false; # Required for Determinate Nix Installer

  # Set the host-specific UUID
  custom.nix-mount.uuid = "E1A6C722-457C-4C80-AA6C-098431B3BD0D";

  programs.fish.enable = true;

  services.tailscale.enable = true;

  users.users.deepwatrcreatur = {
    name = "deepwatrcreatur";
    home = "/Users/deepwatrcreatur";
  };

  system.stateVersion = 4;
}

