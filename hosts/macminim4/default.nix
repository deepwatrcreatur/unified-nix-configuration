{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../../modules/nix-darwin
    ../../modules/nix-darwin/pam.nix
    ./rsync.nix
    ./system-defaults.nix
    ./nix-store-uuid.nix
    ./homebrew.nix
  ];

  nix.enable = false; # Required for Determinate Nix Installer

  environment.systemPackages = [
  ];

  programs.fish.enable = true;

  services.tailscale.enable = true;

  # Define the primary user for user-specific settings
  # required to enable some recently-added functionality
  system.primaryUser = "deepwatrcreatur";

  users.users.deepwatrcreatur = {
    name = "deepwatrcreatur";
    home = "/Users/deepwatrcreatur";
  };

  home-manager.users.deepwatrcreatur = {
    imports = [
      ../../modules/home-manager
    ];
    programs.attic-client.enable = true;
  };
  system.stateVersion = 6;
}
