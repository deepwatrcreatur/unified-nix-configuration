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

  # Add packages
  home.packages = [
  ];

  # Configure programs
  programs.bash.enable = true; 
}
