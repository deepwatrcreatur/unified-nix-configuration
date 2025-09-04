# users/deepwatrcreatur/hosts/homeserver/default.nix
{ config, pkgs, lib,  ... }:

{
  imports = [
    ./homeserver-justfile.nix
    ./nh.nix
    ./rbw.nix
    ../../../../modules/home-manager/git.nix
    ../../../../modules/home-manager/gpg-cli.nix
    ../../../../modules/home-manager/linuxbrew.nix
    ../.. # default module for user
    #../../../../modules/home-manager/rclone.nix
  ];

  # Set the username and home directory for Home Manager
  home.username = "deepwatrcreatur";
  home.homeDirectory = "/home/deepwatrcreatur"; # Home directory for the root user

  # Add packages
  home.packages = [
  ];

  # Configure programs
  programs.bash.enable = true; 
  
  # Let Home Manager manage itself if you want the `home-manager` command available
  programs.home-manager.enable = true;

  home.stateVersion = "24.11";
}
