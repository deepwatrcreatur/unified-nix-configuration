{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nix-inspect
  ];
}
