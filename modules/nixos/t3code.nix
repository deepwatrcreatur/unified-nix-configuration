# modules/nixos/t3code.nix
# Dendritic Opt-in NixOS Module for T3 Code (Theo Browne @t3dotgg)
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.apps.t3code;
in
{
  options.modules.desktop.apps.t3code = {
    enable = lib.mkEnableOption "T3 Code - Agentic AI Coding GUI Harness by Theo Browne (@t3dotgg)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.t3code ];
  };
}
