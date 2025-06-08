{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/nix-darwin
    ./system-defaults.nix
    ./nix-store-uuid.nix
    ./just.nix
    ./homebrew.nix
  ];

  nix.enable = false; # Required for Determinate Nix Installer

  programs.fish.enable = true;
    
  services.tailscale.enable = true;

  # Define the primary user for user-specific settings
  # required to enable some recently-added functionality
  system.primaryUser = "deepwatrcreatur";
  
  users.users.deepwatrcreatur = {
    name = "deepwatrcreatur";
    home = "/Users/deepwatrcreatur";
  };

  system.stateVersion = 6;
}
