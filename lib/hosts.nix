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
  #   ddnsServices: public DNS labels that the router DDNS owner should
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
        "pangolin"
        "netalertx"
        "graylog"
        "status"
      ];
      # Internal-only admin services (homelab/management only, not public).
      # These become CNAMEs in local DNS and are proxied by local Caddy.
      internalAdminServices = {
        technitium = 5380;
        netdata = 19999;
        prometheus = 9090;
        evebox = 5636;
        synology = 5001;
        # Standby router's (elitedesk) Grafana, proxied so its login is TLS.
        standby-grafana = 3001;
      };
      ddnsServices = [
        "@"
        "homelab"
        "authentik"
        "paperless"
        "scrypted"
        "roundtable"
        "status"
      ];
      description = "Main router/firewall running NixOS";
    };

    elitedesk = {
      sshHostname = "192.168.100.98";
      sshUser = "deepwatrcreatur";
      # Standby router: no production LAN IP advertised in DNS until promotion.
      includeDns = false;
      description = "Bare-metal router host (HP EliteDesk), standby to router";
    };

    router-bootstrap = {
      ip = null;
      sshUser = "deepwatrcreatur";
      includeDns = false;
      includeSsh = false;
      description = "Minimal bootstrap output for router-class installs";
    };

    # Proxmox Hypervisors
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


    # Networking Equipment (10.10.18.0/24)
    # Switches use .10-.19, access points .20-.29. Names follow
    # sw-<manufacturer>-<model>. `managementUrl` puts a device on the
    # homepage's Networking section; it uses the IP, not a DNS name, so the
    # link still works when DNS does not.
    sw-main = {
      ip = "10.10.18.10";
      includeSsh = false;
      dhcpReservation = {
        macAddress = "1c:2a:a3:1e:c3:51";
        scope = "LAN";
      };
      # HRUI (Shenzhen HongRui) LG510S-4T2XS, from SNMP sysDescr on
      # 2026-11-24 after the switch moved to DHCP. It keeps the name sw-main
      # because gatus, checks and the cutover script use it. SNMP v2c
      # (IF-MIB) is on; routers scrape it (nix-clan-homelab).
      managementUrl = "http://10.10.18.10";
      description = "Core switch (HRUI LG510S-4T2XS, 4x 10G RJ45 / 2x SFP+)";
    };

    sw-cisco-sg300-52p = {
      ip = "10.10.18.11";
      includeSsh = false;
      dhcpReservation = {
        macAddress = "00:08:32:53:9f:4e";
        scope = "LAN";
      };
      managementUrl = "http://10.10.18.11";
      description = "Cisco SG300-52P (52-port PoE, managed)";
    };

    sw-dell-n1124t-on = {
      ip = "10.10.18.12";
      includeSsh = false;
      dhcpReservation = {
        macAddress = "14:18:77:15:97:e8";
        scope = "LAN";
      };
      managementUrl = "http://10.10.18.12";
      description = "Dell N1124T-ON (24-port, managed)";
    };

    sw-hp-2910al-48g-poe = {
      ip = "10.10.18.13";
      includeSsh = false;
      dhcpReservation = {
        macAddress = "f0:92:1c:cc:57:00";
        scope = "LAN";
      };
      managementUrl = "http://10.10.18.13";
      description = "HP 2910al-48G-PoE (J9148A)";
    };

    sw-dell-powerconnect = {
      ip = "10.10.18.14";
      includeSsh = false;
      dhcpReservation = {
        macAddress = "d0:67:e5:ba:fb:68";
        scope = "LAN";
      };
      managementUrl = "http://10.10.18.14";
      # TODO(nch-sny.22): model hidden before login (GoAhead web UI).
      description = "Dell PowerConnect (model unknown)";
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

    atiyas-airport-extreme = {
      ip = "10.10.18.23";
      includeSsh = false;
      dhcpReservation = {
        macAddress = "f8:1e:df:f7:54:8c";
        scope = "LAN";
      };
      description = "AirPort Express/Extreme switch";
    };

    # Dedicated Infrastructure Servers (Baremetal)
    emerald = {
      ip = "10.10.11.55";
      sshUser = "deepwatrcreatur";
      dhcpReservation = {
        macAddress = "34:5a:60:01:5e:f8"; # onboard RTL8126 5GbE (enp9s0); Intel SFP+ enp1s0f0 is 90:e2:ba:7f:e0:3c
        scope = "LAN";
      };
      aliases = [
        "tomahawk"
        "attic-cache"
        "cache"
        "nix-cache"
      ];
      description = "Nix binary cache server on baremetal (MSI Tomahawk)";
    };

    # LXC Containers

    apt-cache = {
      ip = "10.10.11.42";
      aliases = [ "apt-proxy" ];
      includeSsh = false;  # No SSH access configured
      description = "APT caching proxy";
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
      ip = "10.10.11.84";
      aliases = [ "ha" ];
      includeSsh = false;
      description = "Home Assistant (Podman container on podman host)";
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

    "418" = {
      ip = "10.10.10.59";
      includeSsh = false;
      dhcpReservation = {
        macAddress = "ec:71:db:c6:f4:f3";
        scope = "LAN";
      };
      description = "418 entrance doorbell camera";
    };

    "420" = {
      ip = "10.10.10.60";
      includeSsh = false;
      dhcpReservation = {
        macAddress = "ec:71:db:04:df:fd";
        scope = "LAN";
      };
      description = "420 entrance doorbell camera";
    };

    podman = {
      ip = "10.10.11.84";
      sshUser = "deepwatrcreatur";
      aliases = [ "plex" ];
      dhcpReservation = {
        macAddress = "BC:24:11:51:F9:5B";
        scope = "LAN";
      };
      description = "Podman container host (Plex)";
    };

    scrypted-lxc = {
      ip = "10.10.11.85";
      sshUser = "root";
      dhcpReservation = {
        macAddress = "BC:24:11:18:16:BD";
        scope = "LAN";
      };
      description = "Dedicated Scrypted LXC container on pve-rog";
    };

    synology-dsm = {
      ip = "10.10.11.88";
      sshUser = "deepwatrcreatur";
      aliases = [
        "dsm"
      ];
      dhcpReservation = {
        macAddress = "BC:24:11:53:D5:D0";
        scope = "LAN";
      };
      description = "Synology DSM virtual machine on pve-rog";
    };

    # Workstations
    phoenix = {
      ip = "10.10.11.92";
      sshUser = "deepwatrcreatur";
      dhcpReservation = {
        macAddress = "24:8A:07:8D:66:86";
        scope = "LAN";
      };
      description = "Phoenix workstation";
    };

    # Keep the operational address and DHCP lease while Lattitude remains online;
    # NixOS build composition has moved to nix-clan-homelab.
    lattitude = {
      ip = "10.10.11.47";
      sshUser = "deepwatrcreatur";
      dhcpReservation = {
        macAddress = "fc:15:b4:03:06:0a";
        scope = "LAN";
      };
      description = "Latitude laptop - Sway desktop kiosk (migrated)";
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
