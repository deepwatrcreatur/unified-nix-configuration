# lib/hosts.nix
# Authority: operational/network-layer metadata — SSH access, DNS names, IP
# addresses, DHCP reservations, public ingress routing, and DDNS labels.
# This file does NOT own NixOS build composition (system type, hostPath,
# aspects); that lives in den/inventory/hosts.nix. The two files are kept in
# sync by the alignment checks in outputs/checks.nix. If you rename a host,
# update both files.
#
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
      sshAliases = [ ];
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
        "roundtable"
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
        "roundtable"
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
    pve-elitedesk = {
      ip = "10.10.11.44";
      sshUser = "root";
      description = "Proxmox node - HP EliteDesk";
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

    pve-z170 = {
      ip = "10.10.11.59";
      sshUser = "root";
      description = "Proxmox node - ASRock Z170 ITX/AC";
    };

    # Networking Equipment
    sw-main = {
      ip = "10.10.18.10";
      includeSsh = false;
      dhcpReservation = {
        macAddress = "1c:2a:a3:1e:c3:51";
        scope = "LAN";
      };
      description = "Core Switch";
    };

    ap-ruqayya = {
      ip = "10.10.18.20";
      includeSsh = false;
      dhcpReservation = {
        macAddress = "54:D7:E3:C7:51:80";
        scope = "LAN";
      };
      description = "AP25 Ruqayya Bedroom";
    };
    ap-nosheen-living = {
      ip = "10.10.18.21";
      includeSsh = false;
      dhcpReservation = {
        macAddress = "A8:5B:F7:C2:0A:42";
        scope = "LAN";
      };
      description = "AP22 Nosheen Living Room";
    };
    ap-nosheen-bedroom = {
      ip = "10.10.18.22";
      includeSsh = false;
      dhcpReservation = {
        macAddress = "FC:7F:F1:CC:E1:CA";
        scope = "LAN";
      };
      description = "AP11 Nosheen Bedroom";
    };

    # LXC Containers
    attic-cache = {
      ip = "10.10.11.39";
      sshUser = "root";
      dhcpReservation = {
        macAddress = "BC:24:11:CE:9D:D6";
        scope = "LAN";
      };
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
      dhcpReservation = {
        macAddress = "BC:24:11:A9:BB:ED";
        scope = "LAN";
      };
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

    vaglio = {
      ip = "10.10.11.71";
      sshUser = "deepwatrcreatur";
      dhcpReservation = {
        macAddress = "BC:24:11:A4:02:7A";
        scope = "LAN";
      };
      description = "Dedicated Vaglio (Roundtable) discussion orchestrator";
    };

    homeassistant = {
      ip = "10.10.11.18";
      aliases = [ "ha" ];
      includeSsh = false;
      description = "Home Assistant VM";
    };

    phoenix-hp-m477 = {
      ip = "10.10.11.56";
      includeSsh = false;
      includeDns = false;
      dhcpReservation = {
        macAddress = "10:62:e5:26:58:c2";
        scope = "LAN";
      };
      description = "HP PageWide Pro 477dn MFP printer/scanner";
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
      dhcpReservation = {
        macAddress = "BC:24:11:15:B2:BB";
        scope = "LAN";
      };
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
