# hosts/common-darwin.nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ./nix-mount.nix
  ];
  
  system.defaults.finder.AppleShowAllExtensions = true;
  
  environment.systemPackages = with pkgs; [
  ];

}

