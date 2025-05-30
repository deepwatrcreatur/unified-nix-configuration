# users/root/hosts/proxmox.nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ../.. # default config for root
    ./homeserver-fish-extra.nix
    ./homeserver-justfile.nix
    ./nh.nix
  ];

  # Set the username and home directory for Home Manager
  home.username = "root";
  home.homeDirectory = "/root"; # Home directory for the root user

  # Add packages
  home.packages = [
  ];

  # Configure programs
  programs.bash.enable = true; 
  
  # Let Home Manager manage itself if you want the `home-manager` command available
  programs.home-manager.enable = true;
}
