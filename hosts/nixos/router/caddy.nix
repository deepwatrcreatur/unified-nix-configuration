{ config, pkgs, lib, ... }:

let
  topology = config.router.topology;
  routerHost = topology.routerHost;
  lanNetwork = topology.networks.lan;
  isPrimaryRouter = config.networking.hostName == "router";
  homeAssistantHost = topology.hosts.homeassistant;
  authentikHost = topology.hosts.authentik-host;
  podmanHost = topology.hosts.podman;
  roundtableHost = topology.hosts.vaglio;
  scryptedHost = topology.hosts.scrypted-lxc;
  mkFqdn = label: "${label}.${topology.domain}";

  # Optional secrets library for graceful degradation
  optSec = import ../../../lib/optional-secrets.nix { inherit lib; };

  # Check if cloudflare secret exists (defined in configuration.nix, checked here for preStart logic)
  cfSecret = optSec.mkSecret "cloudflare-api-key" {
    file = ../../../secrets-agenix/cloudflare_ddns_API_token.age;
  };

  waitForPrimaryDnsWarmup = pkgs.writeShellScript "router-caddy-wait-for-primary-dns-warmup" ''
    set -euo pipefail

    for _ in {1..45}; do
      if ${pkgs.curl}/bin/curl --max-time 2 -fsS http://127.0.0.1:5380/api/dns/status >/dev/null 2>&1 \
        && ${pkgs.coreutils}/bin/timeout 2s \
          ${pkgs.glibc.bin}/bin/getent ahostsv4 api.cloudflare.com >/dev/null 2>&1; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done

    echo "router-caddy: upstream DNS was not ready after 45 seconds; continuing startup" >&2
  '';
in
{
  services.caddy = {
    enable = true;
    email = "deepwatrcreatur@gmail.com";
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/cloudflare@v0.2.3"
      ];
      hash = "sha256-to0fhW7LWBocw1ccpPQ7e2nod7iJO9gkWZpjHsZDeu4=";
    };
    environmentFile = "/run/caddy/caddy.env";

    # Global Caddy configuration
    globalConfig = ''
      # ACME/Let's Encrypt configuration
      email deepwatrcreatur@gmail.com
      acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}

      # Use staging for testing, comment out for production
      # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
    '';

    virtualHosts = {
      # Main domain - redirect to www or dashboard
      "${topology.domain}" = {
        extraConfig = ''
          redir https://x.com/deepwatrcreatur permanent
        '';
      };

      # WWW subdomain - serve main site or redirect to dashboard
      "${mkFqdn "www"}" = {
        extraConfig = ''
          redir https://x.com/deepwatrcreatur permanent
        '';
      };

      # Router dashboard
      "${mkFqdn "dashboard"}" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8888
        '';
      };

      "${mkFqdn "homelab"}" = {
        extraConfig = ''
          @trusted remote_ip ${lanNetwork.cidr} 100.64.0.0/10 fd7a:115c:a1e0::/48
          handle @trusted {
            reverse_proxy 127.0.0.1:8888
          }

          respond "Access restricted to home LAN and Tailnet" 403
        '';
      };

      "${mkFqdn "home-assistant"}" = {
        extraConfig = ''
          reverse_proxy ${homeAssistantHost.ip}:8123
        '';
      };

      "${mkFqdn "authentik"}" = {
        extraConfig = ''
          reverse_proxy ${authentikHost.ip}:9000
        '';
      };

      "${mkFqdn "paperless"}" = {
        extraConfig = ''
          reverse_proxy ${podmanHost.ip}:18000
        '';
      };

      "${mkFqdn "nightscout"}" = {
        extraConfig = ''
          reverse_proxy ${podmanHost.ip}:11337
        '';
      };

      "${mkFqdn "scrypted"}" = {
        extraConfig = ''
          reverse_proxy https://${scryptedHost.ip}:10443 {
            transport http {
              tls_insecure_skip_verify
            }
          }
        '';
      };

      "${mkFqdn "roundtable"}" = {
        extraConfig = ''
          reverse_proxy ${roundtableHost.ip}:4000
        '';
      };

      "${mkFqdn "grafana"}" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3001
        '';
      };

      # Internal-only admin services
      "${mkFqdn "technitium"}" = {
        extraConfig = ''
          @trusted remote_ip ${lanNetwork.cidr} 100.64.0.0/10 fd7a:115c:a1e0::/48
          handle @trusted {
            reverse_proxy 127.0.0.1:5380
          }
          respond "Access restricted to home LAN and Tailnet" 403
        '';
      };

      "${mkFqdn "netdata"}" = {
        extraConfig = ''
          @trusted remote_ip ${lanNetwork.cidr} 100.64.0.0/10 fd7a:115c:a1e0::/48
          handle @trusted {
            reverse_proxy 127.0.0.1:19999
          }
          respond "Access restricted to home LAN and Tailnet" 403
        '';
      };

      "${mkFqdn "prometheus"}" = {
        extraConfig = ''
          @trusted remote_ip ${lanNetwork.cidr} 100.64.0.0/10 fd7a:115c:a1e0::/48
          handle @trusted {
            reverse_proxy 127.0.0.1:9090
          }
          respond "Access restricted to home LAN and Tailnet" 403
        '';
      };

      "${mkFqdn "evebox"}" = {
        extraConfig = ''
          @trusted remote_ip ${lanNetwork.cidr} 100.64.0.0/10 fd7a:115c:a1e0::/48
          handle @trusted {
            reverse_proxy 127.0.0.1:5636
          }
          respond "Access restricted to home LAN and Tailnet" 403
        '';
      };

      "http://${routerHost.ip}" = {
        extraConfig = ''
          root * /srv/pxe
          file_server browse
        '';
      };
    };
  };

  # Open firewall for Caddy
  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
  };

  # Ensure Caddy can access the services and prepare its dynamic DNS token
  systemd.services.caddy = {
    after = [
      "network-online.target"
      "technitium-dns-server.service"
    ];
    wants = [
      "network-online.target"
      "technitium-dns-server.service"
    ];
    preStart = ''
      install -d -m 0750 -o caddy -g caddy /run/caddy
      ${lib.optionalString cfSecret.exists ''
        token="$(tr -d '\n' < ${config.age.secrets.cloudflare-api-key.path})"
        test -n "$token"
        printf 'CLOUDFLARE_API_TOKEN=%s\n' "$token" > /run/caddy/caddy.env
        chown caddy:caddy /run/caddy/caddy.env
        chmod 0400 /run/caddy/caddy.env
      ''}
      ${lib.optionalString (!cfSecret.exists) ''
        # Without the Cloudflare secret, keep an empty env file so Caddy can
        # still start on local-only or lab setups.
        : > /run/caddy/caddy.env
        chown caddy:caddy /run/caddy/caddy.env
        chmod 0400 /run/caddy/caddy.env
      ''}
      ${lib.optionalString isPrimaryRouter ''
        ${waitForPrimaryDnsWarmup}
      ''}
    '';
    serviceConfig = {
      # The preStart script creates this file, so it must be optional at the
      # unit level or systemd will fail before preStart gets a chance to run.
      EnvironmentFile = lib.mkForce [ "-/run/caddy/caddy.env" ];
      PermissionsStartOnly = true;
    };
  };

}
