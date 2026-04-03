# lib/hosts.nix
# Single source of truth for all homelab hosts
# Used by: DNS zone config, SSH config, Ansible inventory
{
  # Domain for all hosts
  domain = "deepwatercreature.com";

  # Shared network definitions for the homelab router role. Host entries below
  # should derive their concrete addresses from these where possible instead of
  # repeating raw CIDR/prefix literals across modules.
  networks = {
    lan = {
      cidr = "10.10.0.0/16";
      prefixLength = 16;
    };

    management = {
      cidr = "192.168.100.0/24";
      prefixLength = 24;
    };
  };

  # Host definitions
  # Each host can have:
  #   ip: IPv4 address (required)
  #   ipv6: IPv6 address (optional)
  #   sshUser: default SSH user (optional, defaults to "deepwatrcreatur")
  #   sshHostname: optional SSH target that differs from the DNS/inventory host
  #                address. Useful when a machine has a separate management
  #                interface but still owns a different production IP.
  #   aliases: additional machine names for this host. These are emitted into
  #            SSH config as aliases for the same target, and may also be used
  #            by DNS generation when appropriate.
  #            (e.g. "dns" and "dhcp" are identity aliases for the router machine)
  #   publicIngressServices: public service subdomains fronted by this host via
  #             a reverse proxy (e.g. "authentik" is a service proxied through
  #             router/Caddy, not the router machine itself). Kept separate
  #             from aliases so inventory checks can detect collisions between
  #             service names and machine hostnames.
  #   ddnsServices: public DNS labels that Caddy's dynamic_dns plugin should
  #                 publish for this host at Cloudflare. This is only for
  #                 internet-facing ingress names, not general internal host
  #                 registration, which comes from Technitium/DHCP.
  #                 This can be narrower than `publicIngressServices` when some names are
  #                 handled intentionally outside dynamic DNS (for example a
  #                 manual Cloudflare CNAME).
  #   description: human-readable description (optional)
  #   includeSsh: whether to include in SSH config (default: true)
  #   includeDns: whether to include in DNS zone (default: true)
  #   dhcpReservation: optional DHCP reservation metadata for Technitium-backed
  #                    dynamic hosts. When present, router can derive a stable
  #                    lease from inventory instead of pinning the guest config.

  hosts = {
    # Core Infrastructure
    router = {
      ip = "10.10.10.1";
      sshHostname = "192.168.100.100";
      sshUser = "deepwatrcreatur";
      # Infrastructure identity aliases — other names for the router machine itself
      aliases = [
        "dns"
        "dhcp"
        "firewall"
        "router-management"
      ];
      # Public service subdomains fronted by Caddy on this host.
      # DNS CNAMEs for these point at router, but the actual service runs elsewhere.
      publicIngressServices = [
        "www"
        "dashboard"
        "grafana"
        "homelab"
        "home-assistant"
        "authentik"
        "paperless"
        "scrypted"
        "nightscout"
      ];
      # Internal-only admin services (homelab/management only, not public).
      # These become CNAMEs in local DNS and are proxied by local Caddy.
      internalAdminServices = {
        technitium = 5380;
        netdata = 19999;
        prometheus = 9090;
      };
      ddnsServices = [
        "@"
        "homelab"
        "authentik"
        "paperless"
        "scrypted"
        "nightscout"
      ];
      description = "Main router/firewall running NixOS";
    };

    router-backup = {
      sshHostname = "192.168.100.99";
      sshUser = "deepwatrcreatur";
      includeDns = false;
      description = "Emergency failover router with a dedicated management interface";
    };

    router-bootstrap = {
      ip = null;
      sshUser = "deepwatrcreatur";
      includeDns = false;
      includeSsh = false;
      description = "Minimal bootstrap output for router-class installs";
    };

    # Proxmox Hypervisors
    pve-lattitude = {
      ip = "10.10.11.47";
      sshUser = "root";
      description = "Proxmox node - lattitude laptop";
    };

    pve-rog = {
      ip = "10.10.11.53";
      sshUser = "root";
      description = "Proxmox node - ROG laptop";
    };

    pve-strix = {
      ip = "10.10.11.57";
      sshUser = "root";
      description = "Proxmox node - Strix";
    };

    pve-tomahawk = {
      ip = "10.10.11.55";
      sshUser = "root";
      description = "Proxmox node - Tomahawk";
    };

    pve-z170 = {
      ip = "10.10.11.59";
      sshUser = "root";
      description = "Proxmox node - ASRock Z170 ITX/AC";
    };

    # LXC Containers
    attic-cache = {
      ip = "10.10.11.39";
      sshUser = "root";
      aliases = [ "cache" "nix-cache" ];
      description = "Nix binary cache server";
    };

    apt-cache = {
      ip = "10.10.11.42";
      aliases = [ "apt-proxy" ];
      includeSsh = false;  # No SSH access configured
      description = "APT caching proxy";
    };

    rustdesk = {
      ip = "10.10.11.68";
      sshUser = "root";
      description = "RustDesk server";
    };

    homeserver = {
      ip = "10.10.11.69";
      sshUser = "deepwatrcreatur";
      aliases = [ "semaphore" ];
      description = "Home automation, Semaphore Ansible UI";
    };

    authentik-host = {
      ip = "10.10.11.70";
      sshUser = "deepwatrcreatur";
      dhcpReservation = {
        macAddress = "BC:24:11:A4:01:6F";
        scope = "LAN";
      };
      description = "Dedicated Authentik identity host";
    };

    homeassistant = {
      ip = "10.10.11.18";
      aliases = [ "ha" ];
      includeSsh = false;
      description = "Home Assistant VM";
    };

    podman = {
      ip = "10.10.11.84";
      sshUser = "deepwatrcreatur";
      aliases = [ "plex" ];
      description = "Podman container host (Plex)";
    };

    # Workstations
    workstation = {
      ip = "10.10.11.73";
      sshUser = "deepwatrcreatur";
      description = "Primary workstation";
    };

    phoenix = {
      ip = "10.10.11.72";
      sshUser = "deepwatrcreatur";
      description = "Phoenix workstation";
    };

    # Inference Servers
    inference1 = {
      ip = "10.10.11.131";
      sshUser = "deepwatrcreatur";
      dhcpReservation = {
        macAddress = "BC:24:11:E4:45:B0";
        scope = "LAN";
      };
      description = "GPU inference VM 1";
    };

    inference2 = {
      ip = "10.10.11.132";
      sshUser = "deepwatrcreatur";
      description = "GPU inference VM 2";
    };

    inference3 = {
      ip = "10.10.11.133";
      sshUser = "deepwatrcreatur";
      description = "GPU inference VM 3";
    };

    # External/special hosts
    infisical = {
      ip = null;  # Uses DNS name
      hostname = "infisical.deepwatercreature.com";
      sshUser = "deepwatrcreatur";
      includeDns = false;  # External service
      description = "Secrets management";
    };
  };
}
