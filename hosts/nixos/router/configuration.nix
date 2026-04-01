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
    type = "router";
    primaryUser = "deepwatrcreatur";
    gpu.type = "none";
    desktop.enable = false;
    networking = {
      enableTailscale = true;
      enableAvahi = false;
    };
    services = {
      enableSsh = true;
      enableDocker = false;
      enablePodman = true;
      iperf3.enable = true;
    };
  };

  # I226-V dual-port NIC via PCI passthrough gets PCI-bus-derived names in the VM.
  # hostpci0 (0000:03:00.0 on host) → enp6s16 (LAN), hostpci1 (0000:04:00.0 on host) → enp6s17 (WAN).
  # Inside the VM both NICs appear on bus 6 (slots 16/17). Management virtio NIC retains ens18.
  services.router-networking = {
    enable = true;
    wan.device = "enp6s17";
    routedInterfaces = {
      lan = {
        device = "enp6s16";
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
        device = "enp6s17";
        role = "wan";
        label = "WAN";
        bandwidth = "1Gbit";
      };
      lan = {
        device = "enp6s16";
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
    trustedTcpPorts = [ 80 443 ];
    hairpinNat.enable = true;
    trustedUdpPorts = [ ];
    wanUdpPorts = [ 41641 ];
    extraInputRules = ''
      iifname {"enp6s16"} tcp dport 5201 accept comment "iperf3 from LAN"
    '';
  };

  services.router-homelab.sshTarget = "ssh router.deepwatercreature.com";

  imports = [ ../../../modules/nixos/router/common.nix ];

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

  home-manager.users.deepwatrcreatur = {
    imports = [
      ../../../modules/home-manager/git.nix
      ../../../modules/home-manager/gpg-cli.nix
      ../../../users/deepwatrcreatur/hosts/router
    ];

    home.username = "deepwatrcreatur";
    home.homeDirectory = "/home/deepwatrcreatur";
    programs.home-manager.enable = true;
  };

  home-manager.extraSpecialArgs.hostName = "router";
  home-manager.extraSpecialArgs.isDesktop = false;

  # EFI/Limine bootloader — OVMF QEMU VM with no legacy BIOS.
  boot.loader.grub.enable = false;
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  my.agenix.machineIdentity.enable = true;

  # Logs disk is on scsi1 (spinning disk), formatted by disko as disk-logs-logs.
  # router-log-storage handles the mount; disko only formats the partition.

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
    settings.PermitRootLogin = "prohibit-password";
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
      "10.10.0.0/16"
    ];
  };

  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    shell = pkgs.fish;
  };

  services.ssh-keys-manager.username = "deepwatrcreatur";

  programs.fish.enable = true;

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    tmux
  ];

  # Agenix secrets - uses optional-secrets library for graceful degradation
  age.secrets = secrets.definitions;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
