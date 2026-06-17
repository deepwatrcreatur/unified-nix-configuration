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
    ../../modules/common/utility-packages.nix
    ./rsync.nix
    ./nix-store-uuid.nix
    ./homebrew.nix
  ];

  nix.enable = false; # Required for Determinate Nix Installer

  environment.systemPackages = with pkgs; [
    fish  # Ensure fish is available in nix store for tmux
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  programs.fish.enable = true;

  services.tailscale.enable = true;

  # Define the primary user for user-specific settings
  # required to enable some recently-added functionality
  system.primaryUser = "deepwatrcreatur";

  system.stateVersion = 6;
}
