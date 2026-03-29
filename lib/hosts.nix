# lib/hosts.nix
# Single source of truth for all homelab hosts
# Used by: DNS zone config, SSH config, Ansible inventory
{
  # Domain for all hosts
  domain = "deepwatercreature.com";

  # Host definitions
  # Each host can have:
  #   ip: IPv4 address (required)
  #   ipv6: IPv6 address (optional)
  #   sshUser: default SSH user (optional, defaults to "deepwatrcreatur")
  #   aliases: DNS CNAME aliases that are other names for this machine itself
  #            (e.g. "router" and "dns" are identity aliases for the gateway machine)
  #   services: public service subdomains fronted by this host via a reverse proxy
  #             (e.g. "authentik" is a service proxied through gateway/Caddy, not the
  #             gateway machine itself).  Kept separate from aliases so inventory checks
  #             can detect collisions between service names and machine hostnames.
  #   description: human-readable description (optional)
  #   includeSsh: whether to include in SSH config (default: true)
  #   includeDns: whether to include in DNS zone (default: true)
  #   dhcpReservation: optional DHCP reservation metadata for Technitium-backed
  #                    dynamic hosts. When present, gateway can derive a stable
  #                    lease from inventory instead of pinning the guest config.

  hosts = {
    # Core Infrastructure
    gateway = {
      ip = "10.10.10.1";
      sshUser = "deepwatrcreatur";
      # Infrastructure identity aliases — other names for the gateway machine itself
      aliases = [
        "router"
        "dns"
        "dhcp"
        "firewall"
      ];
      # Public service subdomains fronted by Caddy on this host.
      # DNS CNAMEs for these point at gateway, but the actual service runs elsewhere.
      services = [
        "www"
        "dashboard"
        "grafana"
        "homelab"
        "home-assistant"
        "authentik"
        "paperless"
        "scrypted"
        "2fauth"
        "nightscout"
        "marreta"
        "linkwarden"
      ];
      description = "Main router/firewall running NixOS";
    };

    # Proxmox Hypervisors
    pve-gateway = {
      ip = "10.10.11.52";
      sshUser = "root";
      description = "Proxmox node - gateway";
    };

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

    nixoslxc = {
      ip = "10.10.11.40";
      sshUser = "deepwatrcreatur";
      description = "Generic NixOS LXC template";
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

    casaos = {
      ip = "10.10.11.77";
      sshUser = "root";
      description = "CasaOS container host";
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

    # Services (DNS only, no SSH)
    npm = {
      ip = "10.10.11.37";
      aliases = [ "proxy" ];
      includeSsh = false;
      description = "Nginx Proxy Manager";
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
