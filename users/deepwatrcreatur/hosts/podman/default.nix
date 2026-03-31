# users/deepwatrcreatur/hosts/podman/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../.. # default config for deepwatrcreatur (up 2 levels)
    ../../../../modules/home-manager/git.nix
    ../../../../modules/home-manager/gpg-agent-ssh.nix
    ../../../../modules/home-manager/agenix-user-secrets.nix
  ];

  # Set home directory for Home Manager
  home.homeDirectory = "/home/deepwatrcreatur";

  # Podman-specific packages
  home.packages = with pkgs; [
    podman-compose
    dive  # Container image explorer
  ];

  # Configure programs
  programs.bash.enable = true;

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
