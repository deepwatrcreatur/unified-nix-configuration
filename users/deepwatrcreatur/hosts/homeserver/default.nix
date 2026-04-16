# users/deepwatrcreatur/hosts/homeserver/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../.. # default config for deepwatrcreatur (up 2 levels)
    ./homeserver-justfile.nix
    ./nh.nix
    ./rbw.nix
    ../../../../modules/home-manager/git.nix
    ../../../../modules/home-manager/git-ssh-signing.nix
    ../../../../modules/home-manager/ssh-agent.nix
    ../../../../modules/home-manager/agenix-user-secrets.nix
  ];

  # Set home directory for Home Manager
  home.homeDirectory = "/home/deepwatrcreatur";

  # Add packages
  home.packages = [
  ];

  # Configure programs
  programs.bash.enable = true;

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Disable user-level netrc - NixOS uses system-level /run/nix/nix-ci-netrc
  services.nix-user-config.netrcMachine = null;

  home.stateVersion = "25.05";
}
