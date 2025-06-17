# modules/nix-darwin/common-darwin.nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ./nix-mount.nix
    ../home-manager/env/darwin.nix
  ];

  nixpkgs.config.allowUnfree = true;

  system.defaults.finder.AppleShowAllExtensions = true;
  
  environment.systemPackages = with pkgs; [
  ];

}

