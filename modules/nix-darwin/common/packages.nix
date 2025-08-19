# modules/nix-darwin/common/packages.nix
{ config, pkgs, lib, ... }: {
  environment.systemPackages = with pkgs; [
    watch
  ];
}
