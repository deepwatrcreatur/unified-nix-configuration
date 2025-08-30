{ config, pkgs, ... }:
{
  imports = [../../../../modules/nh.nix];
  
  programs.nh = {
    flake = "/home/deepwatrcreatur/unified-nix-configuration";
    # Specify the hostname for NixOS configurations
    os.hostname = "workstation";
  };
}
