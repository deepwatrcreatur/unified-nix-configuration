# users/root/hosts/omarchy/default.nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ../.. # default config for root
    ./justfile.nix
    ./nh.nix
    ./fish-extra.nix
    ../../../../modules/home-manager # Common home-manager modules
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
