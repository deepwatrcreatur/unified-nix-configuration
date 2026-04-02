{
  sshTarget,
  wanDevice,
  lanDevice,
  managementIpv4Address,
  grafanaDomain,
  grafanaDataDir,
  prometheusStateDir,
  prometheusBindMountPath,
  enableLogStorage ? true,
}:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  optSec = import ../../../modules/helpers/optional-secrets.nix { inherit lib; };

  secrets = optSec.mkSecrets {
    cloudflare-api-key = {
      file = ../../../secrets-agenix/cloudflare_ddns_API_token.age;
    };
    technitium-api-key = {
      file = ../../../secrets-agenix/technitium-api-key.age;
      mode = "0444";
    };
    tailscale-auth-key = {
      file = ../../../secrets-agenix/tailscale-auth-key.age;
    };
  };

  hostsData = import ../../../lib/hosts.nix;
  reservableHosts = lib.filterAttrs (
    _name: host: (host.dhcpReservation or null) != null && (host.ip or null) != null
  ) hostsData.hosts;
in
{
  imports = [ ../../../modules/nixos/router/common.nix ];

  host = {
    type = "router";
    primaryUser = "deepwatrcreatur";
    gpu.type = "none";
    desktop.enable = false;
    networking = {
      enableTailscale = false;
      enableAvahi = false;
    };
    services = {
      enableSsh = true;
      enableDocker = false;
      enablePodman = true;
      iperf3.enable = true;
    };
  };

  services.router-networking = {
    enable = true;
    wan.device = wanDevice;
    routedInterfaces = {
      lan = {
        device = lanDevice;
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
        ipv4Address = managementIpv4Address;
        prefixDelegationMode = "managed";
      };
    };
  };

  services.router-optimizations = {
    enable = true;
    interfaces = {
      wan = {
        device = wanDevice;
        role = "wan";
        label = "WAN";
        bandwidth = "1Gbit";
      };
      lan = {
        device = lanDevice;
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

  services.router-technitium = {
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
    trustedTcpPorts = [ 80 443 ];
    hairpinNat.enable = true;
    trustedUdpPorts = [ ];
    extraInputRules = ''
      iifname {"${lanDevice}"} tcp dport 5201 accept comment "iperf3 from LAN"
    '';
  };

  services.router-homelab.sshTarget = sshTarget;

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

  services.router-tailscale = {
    enable = true;
    authKeyFile = secrets.path "tailscale-auth-key";
    advertiseExitNode = true;
    advertiseRoutes = [ "10.10.0.0/16" ];
    trustedInterface = true;
    openFirewall = true;
  };

  router.monitoring = {
    grafanaDomain = grafanaDomain;
    grafanaDataDir = grafanaDataDir;
    prometheusStateDir = prometheusStateDir;
    prometheusBindMountPath = prometheusBindMountPath;
  };

  boot.loader.grub.enable = false;
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  my.agenix.machineIdentity.enable = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  virtualisation.oci-containers.backend = "podman";

  services.qemuGuest.enable = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
    extraConfig = ''
      Match Address 10.10.10.0/24
        PermitRootLogin yes
    '';
  };

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
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
  };

  services.ssh-keys-manager.username = "deepwatrcreatur";

  programs.fish.enable = true;

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [ tmux ];

  age.secrets = secrets.definitions;

  services.router-log-storage.enable = lib.mkForce enableLogStorage;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
