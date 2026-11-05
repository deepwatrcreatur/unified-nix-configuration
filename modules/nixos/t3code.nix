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
    user = lib.mkOption {
      type = lib.types.str;
      description = "User whose Home Manager T3 Code daemon is configured by this module.";
    };
    tailscaleServe = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Expose the user's T3 Code daemon over Tailscale Serve (HTTPS on :443).
        Makes `user` the Tailscale operator so the unprivileged daemon can manage
        `tailscale serve`. Serve traffic is terminated inside tailscaled, so no
        firewall port needs to be opened for it.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      environment.systemPackages = [ pkgs.t3code ];
      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 3773 ];
    }
    (lib.mkIf cfg.tailscaleServe {
      services.tailscale.extraSetFlags = [ "--operator=${cfg.user}" ];
      home-manager.users.${cfg.user}.services.t3code.tailscale = true;
    })
  ]);
}
