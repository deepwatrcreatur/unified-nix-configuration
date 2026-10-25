# modules/nixos/t3code.nix
# Dendritic Opt-in NixOS Module for T3 Code (Theo Browne @t3dotgg)
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.apps.t3code;
in
{
  options.modules.desktop.apps.t3code = {
    enable = lib.mkEnableOption "T3 Code - Agentic AI Coding GUI Harness by Theo Browne (@t3dotgg)";
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open port 3773 in the firewall for T3 Code server and T3 Connect / mobile pairing.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.t3code ];
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 3773 ];
  };
}
