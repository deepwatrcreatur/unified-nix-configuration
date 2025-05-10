# hosts/common-darwin.nix
{ config, pkgs, lib, ... }:

{
  system.defaults.finder.AppleShowAllExtensions = true;
  
  environment.systemPackages = with pkgs; [
  ];

}

