{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/system/packages.nix
    ../../modules/nix-darwin
    ./nix-store-uuid.nix
  ];

  nix.enable = false; # Required for Determinate Nix Installer

  programs.fish = {
    enable = true;
    shellInit = ""; # Explicitly empty to avoid null
    interactiveShellInit = ""; # Explicitly empty to avoid null
    shellAliases = {
      update = "darwin-rebuild switch --flake /Volumes/Work/unified-nix-configuration#${config.networking.hostName}";
    };
  };
    
  services.tailscale.enable = true;
  
  # Define the primary user for user-specific settings
  # required to enable some recently-added functionality
  system.primaryUser = "deepwatrcreatur";
  
  users.users.deepwatrcreatur = {
    name = "deepwatrcreatur";
    home = "/Users/deepwatrcreatur";
  };

  system.stateVersion = 4;
}
