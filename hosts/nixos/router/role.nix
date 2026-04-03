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
  getAttrByPath = lib.attrByPath;
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

  # Recovery invariants: these assertions fail the build if the properties
  # that make the router usable in standby/dev mode are ever regressed.
  assertions = [
    {
      assertion =
        getAttrByPath
          [ "systemd" "network" "networks" "20-router-lan" "networkConfig" "ConfigureWithoutCarrier" ]
          false
          config
        == true;
      message = ''
        Router invariant violated: 20-router-lan must have ConfigureWithoutCarrier = true.
        Without this, the LAN static IP disappears when the data-plane cable is unplugged,
        causing monitoring (Prometheus, Grafana, Netdata) to cascade into failure on standby/dev boxes.
      '';
    }
    {
      assertion = config.services.qemuGuest.enable;
      message = ''
        Router invariant violated: services.qemuGuest.enable must be true.
        The QEMU guest agent is required for Proxmox to report accurate VM state and
        to support clean shutdown/snapshot from the hypervisor.
      '';
    }
    {
      assertion = builtins.elem "console=ttyS0,115200" config.boot.kernelParams;
      message = ''
        Router invariant violated: boot.kernelParams must include "console=ttyS0,115200".
        The serial console is the recovery path when SSH and the graphical console are broken.
      '';
    }
    {
      assertion =
        !builtins.elem "podman" (getAttrByPath [ "services" "router-dashboard" "services" ] [ ] config);
      message = ''
        Router invariant violated: "podman" must not appear in router-dashboard.services.
        Podman was removed from the router role; leaving it in the dashboard list causes
        the status panel to show a permanently-failed service that no longer exists.
      '';
    }
  ];

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

  # Do not block network-online.target on the data-plane LAN NIC.
  #
  # caddy and router-dashboard wait on network-online.target. With the default
  # anyInterface = false, systemd-networkd-wait-online waits for ALL required
  # interfaces — including LAN (RequiredForOnline = routable). Without carrier,
  # LAN cannot reach "routable", so caddy/dashboard appear stuck in activating
  # even though the management plane is fully usable.
  #
  # anyInterface = true: exit as soon as any one managed interface (management
  # always has carrier) reaches its required state.
  systemd.network.wait-online.anyInterface = true;

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
  systemd.services.systemd-update-utmp.enable = false;

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
    # Management CIDR must be exempt: if authentication failures from the
    # management interface trigger a ban, the recovery path is cut off.
    ignoreIP = [
      "127.0.0.1/8"
      lanNetwork.cidr
      topology.networks.management.cidr
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
