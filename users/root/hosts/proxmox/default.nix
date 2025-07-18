# users/root/hosts/proxmox.nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ../.. # default config for root
    ./proxmox-fish-extra.nix
    ./proxmox-justfile.nix
    ./nh.nix
    #../../../../modules/home-manager/env/standalone-hm.nix
    ../../../../modules/home-manager/gpg-cli.nix
    ../../../../modules/home-manager/git.nix
  ];

  # Add packages to base config for root user
  home.packages = lib.mkAfter [
    # host-specific packages
  ];

  # Configure programs
  programs.bash.enable = true; 
 
}
