# DNS zone configuration for the homelab.
# Each attribute under `zones` is a separate Technitium zone.
{
  zones = {
    "deepwatercreature.com" = {
      # Static host records - these are version controlled and persistent.
      hosts = {
        # Core Infrastructure
        gateway = {
          ipv4 = "10.10.10.1";
          ipv6 = null;
          aliases = [ "router" "dns" "dhcp" "firewall" ];
        };

        attic-cache = {
          ipv4 = "10.10.11.39";
          ipv6 = null;
          aliases = [ "cache" "nix-cache" ];
        };

        workstation = {
          ipv4 = "10.10.11.90";
          ipv6 = null;
        };

        # Proxmox Hypervisors
        pve-gateway = {
          ipv4 = "10.10.11.52";
          ipv6 = null;
        };

        pve-lattitude = {
          ipv4 = "10.10.11.47";
          ipv6 = null;
        };

        pve-rog = {
          ipv4 = "10.10.11.45";
          ipv6 = null;
        };

        pve-strix = {
          ipv4 = "10.10.11.57";
          ipv6 = null;
        };

        pve-tomahawk = {
          ipv4 = "10.10.11.55";
          ipv6 = null;
        };

        # LXC Containers and VMs
        nixoslxc = {
          ipv4 = "10.10.11.40";
          ipv6 = null;
        };

        ansible = {
          ipv4 = "10.10.11.67";
          ipv6 = null;
        };

        rustdesk = {
          ipv4 = "10.10.11.68";
          ipv6 = null;
        };

        homeserver = {
          ipv4 = "10.10.11.69";
          ipv6 = null;
        };

        casaos = {
          ipv4 = "10.10.11.77";
          ipv6 = null;
        };

        # Inference Servers
        inference1 = {
          ipv4 = "10.10.11.131";
          ipv6 = null;
        };

        inference2 = {
          ipv4 = "10.10.11.132";
          ipv6 = null;
        };

        inference3 = {
          ipv4 = "10.10.11.133";
          ipv6 = null;
        };

        # Services
        npm = {
          ipv4 = "10.10.11.37";
          ipv6 = null;
          aliases = [ "proxy" ];
        };
      };

      # Additional CNAME aliases (alternative to per-host aliases above).
      aliases = {
        # "www" = "gateway";
        # "mail" = "gateway";
      };
    };
  };
}
