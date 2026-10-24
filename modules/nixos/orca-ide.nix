# modules/nixos/orca-ide.nix
# Dendritic Opt-in NixOS Module for Orca IDE (https://www.onorca.dev/)
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.apps.orca-ide;
in
{
  options.modules.desktop.apps.orca-ide = {
    enable = lib.mkEnableOption "Orca - Agent Development Environment (ADE) by Stably";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.orca-ide ];
  };
}
