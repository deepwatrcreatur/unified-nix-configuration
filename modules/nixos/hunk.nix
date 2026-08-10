# modules/nixos/hunk.nix
# Dendritic Opt-in NixOS Module for Hunk diff viewer (Linux)
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.desktop.apps.hunk;
  hunkPkg = inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.modules.desktop.apps.hunk = {
    enable = lib.mkEnableOption "Hunk review-first terminal diff viewer";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ hunkPkg ];
  };
}
