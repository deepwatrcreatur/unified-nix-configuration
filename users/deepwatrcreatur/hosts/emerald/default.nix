# users/deepwatrcreatur/hosts/cache-build-server/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../..
    ./justfile.nix
    ./nh.nix
    ./rbw.nix
    ../../../../modules/home-manager/git.nix

    ../../../../modules/home-manager/git-ssh-signing.nix
    ../../../../modules/home-manager/ssh-agent.nix
  ];

  # Set home directory for Home Manager
  home.homeDirectory = "/home/deepwatrcreatur"; # Home directory for the root user

  # Add packages
  home.packages = with pkgs; [
    omasnap
    flameshot
    vivaldi
  ];

  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
  };

  programs.google-chrome = {
    enable = true;
  };

  # Configure programs
  programs.bash.enable = true;

  # Let Home Manager manage itself if you want the `home-manager` command available
  programs.home-manager.enable = true;

  home.stateVersion = "25.11";
}
