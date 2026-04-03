{
  sshTarget,
  wanDevice,
  lanDevice,
  lanIpv4Address,
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
  managementListenAddress = builtins.head (lib.splitString "/" managementIpv4Address);

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

  topology = config.router.topology;
  lanNetwork = topology.networks.lan;
  reservableHosts = lib.filterAttrs (
    _name: host: (host.dhcpReservation or null) != null && (host.ip or null) != null
  ) topology.hosts;
in
{
  imports = [ ../../../modules/nixos/router/common.nix ];

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
      iperf3 = {
        enable = true;
        bindProbeAddress = topology.routerHost.ip;
      };
    };
  };

  services.router-networking = {
    enable = true;
    wan.device = wanDevice;
    routedInterfaces = {
      lan = {
        device = lanDevice;
        ipv4Address = lanIpv4Address;
        dns = [ "127.0.0.1" ];
        domains = [ topology.domain ];
        requiredForOnline = "routable";
        extraRoutes = [
          {
            destination = lanNetwork.cidr;
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
  services.router-homelab.listenAddress = "0.0.0.0";

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
    advertiseExitNode = secrets.exists "tailscale-auth-key";
    advertiseRoutes = lib.optionals (secrets.exists "tailscale-auth-key") [ lanNetwork.cidr ];
    trustedInterface = true;
    openFirewall = true;
  };

  router.monitoring = {
    grafanaDomain = grafanaDomain;
    grafanaDataDir = grafanaDataDir;
    listenAddress = lib.mkForce "0.0.0.0";
    prometheusStateDir = prometheusStateDir;
    prometheusBindMountPath = prometheusBindMountPath;
  };

  services.netdata.config.global."bind to" = "0.0.0.0";

  # Keep the production LAN address present even when the data-plane cable is
  # intentionally unplugged on a standby/dev router. That allows dashboard and
  # router-role services to come up in a degraded-but-testable state.
  systemd.network.networks."20-router-lan".networkConfig.ConfigureWithoutCarrier = true;

  boot.loader.grub.enable = false;
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.kernelParams = [ "console=ttyS0,115200" ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  my.agenix.machineIdentity.enable = true;

  services.qemuGuest.enable = true;
  services.fstrim.enable = true;

  # Proxmox recovery path: keep a serial console available even when SSH or the
  # graphical console path is broken.
  systemd.services."serial-getty@ttyS0".enable = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
    extraConfig = ''
      Match Address ${lanNetwork.cidr}
        PermitRootLogin yes
    '';
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.1/8"
      lanNetwork.cidr
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
