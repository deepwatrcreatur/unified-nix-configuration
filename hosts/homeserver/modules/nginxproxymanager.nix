# ./modules/nixos/services/nginxproxymanager.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.nginx-proxy-manager;
in
{
  options.services.nginx-proxy-manager = {
    enable = lib.mkEnableOption "Enable Nginx Proxy Manager";
  };

  config = lib.mkIf cfg.enable {
    # This module does not depend on SOPS, as NPM handles secrets
    # via its web interface, which is simpler for this use case.

    virtualisation.oci-containers.containers."nginx-proxy-manager" = {
      # Use the official, public NPM image
      image = "jc21/nginx-proxy-manager:latest";
      autoStart = true;
      ports = [
        "80:80"
        "443:443"
        "81:81"
      ];
      volumes = [
        "/var/lib/nginx-proxy-manager/data:/data"
        "/var/lib/nginx-proxy-manager/letsencrypt:/etc/letsencrypt"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/nginx-proxy-manager 0755 root root - -"
      "d /var/lib/nginx-proxy-manager/data 0755 root root - -"
      "d /var/lib/nginx-proxy-manager/letsencrypt 0755 root root - -"
    ];
  };
}
