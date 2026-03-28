{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  # Optional secrets library for graceful degradation when .age files don't exist
  optSec = import ../../../modules/helpers/optional-secrets.nix { inherit lib; };

  # Define all secrets in one place - they gracefully degrade if files don't exist
  secrets = optSec.mkSecrets {
    cloudflare-api-key = {
      file = ../../../secrets-agenix/cloudflare_ddns_API_token.age;
    };
    technitium-api-key = {
      file = ../../../secrets-agenix/technitium-api-key.age;
      mode = "0444"; # World-readable for router-dashboard DynamicUser access
    };
    tailscale-auth-key = {
      file = ../../../secrets-agenix/tailscale-auth-key.age;
    };
  };
in
{
  # Declarative host configuration
  host = {
    type = "gateway";
    primaryUser = "deepwatrcreatur";
    gpu.type = "none";
    desktop.enable = false;
    networking = {
      enableTailscale = true;
      enableAvahi = false;      # Not needed on gateway
    };
    services = {
      enableSsh = true;
      enableDocker = false;
      enablePodman = true;
      iperf3.enable = true;
    };
  };

  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos/common
    ../../../modules/nixos/determinate-netrc-dir.nix
    ../../../modules/nixos/services/iperf3.nix
    ../../../modules/common/utility-packages.nix
    ../../../modules/nixos/keyboard-glitches.nix # Fix stuck keyboard presses in Proxmox VM
    ../../../modules/nixos/snap.nix # Snap package manager support
    ../../../modules/activation-scripts
    inputs.agenix.nixosModules.default # Agenix secrets management
    # Import only specific modules, NOT default (which includes nftables-fasttrack that conflicts with our nftables.nix)
    inputs.nix-router-optimized.nixosModules.router-networking
    inputs.nix-router-optimized.nixosModules.router-firewall
    inputs.nix-router-optimized.nixosModules.router-dns-service
    inputs.nix-router-optimized.nixosModules.router-homelab
    inputs.nix-router-optimized.nixosModules.router-log-storage
    inputs.nix-router-optimized.nixosModules.router-optimizations
    ./networking.nix # Network interface configuration
    ./caddy.nix # Caddy reverse proxy configuration
  ];

  # Router optimizations (hardware offload, fasttrack, queue management)
  services.router-networking = {
    enable = true;
    wan.device = "ens17";
    routedInterfaces = {
      lan = {
        device = "ens16";
        ipv4Address = "10.10.10.1/16";
        dns = [ "127.0.0.1" ];
        domains = [ "deepwatercreature.com" ];
        requiredForOnline = "routable";
        extraRoutes = [
          {
            destination = "10.10.0.0/16";
            scope = "link";
          }
        ];
      };
      management = {
        device = "ens18";
        ipv4Address = "192.168.100.100/24";
        prefixDelegationMode = "managed";
      };
    };
  };

  services.router-optimizations = {
    enable = true;
    interfaces = {
      wan = {
        device = "ens17";
        role = "wan";
        label = "WAN";
        bandwidth = "1Gbit";
      };
      lan = {
        device = "ens16";
        role = "lan";
        label = "LAN";
      };
      management = {
        device = "ens18";
        role = "management";
        label = "Management";
      };
    };
    conntrack-max = 262144;
  };

  services.router-technitium =
    let
      hostsData = import ../../../lib/hosts.nix;
      reservableHosts = lib.filterAttrs (
        _name: host: (host.dhcpReservation or null) != null && (host.ip or null) != null
      ) hostsData.hosts;
    in
    {
      dhcpReservations = lib.mapAttrs (
        name: host: {
          scope = host.dhcpReservation.scope or "LAN";
          macAddress = host.dhcpReservation.macAddress;
          ipAddress = host.ip;
          hostName = name;
          comments = host.description or "";
        }
      ) reservableHosts;
    };

  services.router-firewall = {
    enable = true;
    tailscaleInterface = "tailscale0";
    # Router-hosted HTTPS needs to be reachable from trusted LAN clients too,
    # not just from WAN. Split DNS points service domains at the gateway, so
    # LAN clients hit Caddy on the router itself.
    trustedTcpPorts = [ 80 443 ];
    # Split DNS already points service subdomains at the gateway for LAN clients,
    # but hairpin NAT is a useful fallback for devices that bypass local DNS
    # (for example phones using private DNS/DoH or stale public-cache answers).
    hairpinNat.enable = true;
    trustedUdpPorts = [ ];
    wanUdpPorts = [ 41641 ];
    extraInputRules = ''
      iifname {"ens16"} tcp dport 5201 accept comment "iperf3 from LAN"
    '';
  };

  services.router-homelab = {
    enable = true;
    sshTarget = "ssh gateway.deepwatercreature.com";
    netdataAllowConnectionsFrom = "10.10.*";
    waitForListenAddress = true;
  };

  # Router dashboard configuration
  services.router-dashboard = {
    links = [
      {
        label = "Tech Logs";
        url = "/logs/technitium.html";
        icon = "📜";
      }
      {
        label = "Fail2ban";
        url = "/status/fail2ban.html";
        icon = "🛡️";
      }
    ];
  };

  router.monitoring = {
    grafanaDomain = "gateway.deepwatercreature.com";
    grafanaDataDir = "/var/log/gateway/grafana";
    prometheusStateDir = "gateway-prometheus";
    prometheusBindMountPath = "/var/log/gateway/prometheus";
    prometheusRetentionSize = "40GB";
  };

  services.tailscale = {
    useRoutingFeatures = "server";
    authKeyFile = secrets.path "tailscale-auth-key";
    extraUpFlags = lib.optionals (secrets.exists "tailscale-auth-key") [
      "--advertise-exit-node"
      "--advertise-routes=10.10.0.0/16"
    ];
  };

  # DNS zone management with static hosts imported from external file.
  # Edit ./dns-zone.nix to manage one or more zones.
  services.router.dnsZones =
    let
      dnsConfig = import ./dns-zone.nix;
      defaultNetworks = [
        "10.10.10.0/24"
        "10.10.11.0/24"
      ];
      mkZone = zone: {
        nameserverIP = zone.nameserverIP or "10.10.10.1";
        allowDynamicUpdates = zone.allowDynamicUpdates or true;
        aliases = zone.aliases or { };
        staticHosts = lib.mapAttrs (_name: host: {
          ipAddress = host.ipv4;
          aliases = host.aliases or [ ];
        }) zone.hosts;
        reverseZone = {
          enable = zone.reverseZone.enable or true;
          networks = zone.reverseZone.networks or defaultNetworks;
        };
      };
    in
    if dnsConfig ? zones then
      lib.mapAttrs (_zoneName: zone: mkZone zone) dnsConfig.zones
    else
      {
        "${dnsConfig.domain}" = mkZone dnsConfig;
      };

  # Home manager configuration for gateway
  home-manager.users.deepwatrcreatur = {
    imports = [
      ../../../modules/home-manager/git.nix
      ../../../modules/home-manager/gpg-cli.nix
      ../../../users/deepwatrcreatur/hosts/gateway
    ];

    home.username = "deepwatrcreatur";
    home.homeDirectory = "/home/deepwatrcreatur";
    programs.home-manager.enable = true;
  };

  home-manager.extraSpecialArgs.hostName = "gateway";
  home-manager.extraSpecialArgs.isDesktop = false;

  # Boot loader (GRUB for MBR/BIOS)
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # Install GRUB on the disk
  boot.loader.timeout = 5;
  boot.growPartition = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  my.agenix.machineIdentity.enable = true;

  # Disable custom logging for Technitium - use default state directory
  # The spinning disk logging causes read-only filesystem errors with DynamicUser
  # systemd.services.technitium-dns-server = {
  #   environment = {
  #     TECHNITIUM_DNS_LOG_FOLDER = "/var/log/gateway/technitium";
  #   };
  #   serviceConfig = {
  #     ReadWritePaths = [ "/var/log/gateway/technitium" ];
  #   };
  # };

  services.router-log-storage = {
    enable = true;
    device = "/dev/disk/by-uuid/f4b71c97-3f7f-47b3-a644-d82e051d5343";
    mountPoint = "/var/log/gateway";
    serviceName = "setup-gateway-logs";
    extraDirectories = [
      {
        name = "technitium";
        mode = "0777";
      }
      {
        name = "prometheus";
        user = "prometheus";
        group = "prometheus";
      }
      {
        name = "grafana";
        user = "grafana";
        group = "grafana";
      }
    ];
  };

  # Enable podman for containers
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  virtualisation.oci-containers.backend = "podman";

  # QEMU guest agent for Proxmox
  services.qemuGuest.enable = true;

  # SSH daemon
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password"; # Secure default
    extraConfig = ''
      Match Address 10.10.10.0/24
        PermitRootLogin yes
    '';
  };

  # Fail2ban for SSH brute-force protection
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.1/8"
      "10.10.0.0/16" # LAN network
    ];
  };

  # Define your user account (SSH keys managed by common/ssh-keys.nix)
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    shell = pkgs.fish;
  };

  services.ssh-keys-manager.username = "deepwatrcreatur";

  # Enable fish shell
  programs.fish.enable = true;

  # Allow wheel group to use sudo without password
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    tmux
  ];

  # Agenix secrets - uses optional-secrets library for graceful degradation
  age.secrets = secrets.definitions;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
