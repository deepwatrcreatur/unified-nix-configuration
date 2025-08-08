{ config, pkgs, ... }:
{
  imports = [../../../../modules/nh.nix];
  
  programs.nh = {
    flake = "/root/unified-nix-configuration"
  };
}
