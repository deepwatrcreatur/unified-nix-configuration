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
  inputs,
}:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  optSec = import ../../../lib/optional-secrets.nix { inherit lib; };
  getAttrByPath = lib.attrsets.attrByPath;
  lanListenAddress = builtins.head (lib.splitString "/" lanIpv4Address);
  managementListenAddress = builtins.head (lib.splitString "/" managementIpv4Address);
  managementDevice = "ens18";
  operatorStableSshKey = lib.strings.trim (
    builtins.readFile ../../../ssh-keys/deepwatrcreatur-stable-identity.pub
  );

  secrets = optSec.mkSecrets {
    cloudflare-api-key = {
      file = ../../../secrets-agenix/cloudflare_ddns_API_token.age;
      group = "router-dashboard";
      mode = "0440";
    };
    technitium-api-key = {
      file = ../../../secrets-agenix/technitium-api-key.age;
      mode = "0444";
    };
    kea-ddns-tsig-key = {
      file = ../../../secrets-agenix/kea-ddns-tsig-key.age;
      mode = "0440";
      group = "kea";
    };
    tailscale-auth-key = {
      file = ../../../secrets-agenix/tailscale-auth-key.age;
    };
  };

  topology = config.router.topology;
  lanNetwork = topology.networks.lan;
  managementNetwork = topology.networks.management;
  mkFqdn = label: "${label}.${topology.domain}";
  reservableHosts = lib.filterAttrs (
    _name: host: (host.dhcpReservation or null) != null && (host.ip or null) != null
  ) topology.hosts;
  # Static LAN IP assigned to this router node (distinct from the shared VIP).
  # Used in the DNS VIP SNAT rule below to rewrite outbound reply source.
  staticLanIp = if config.networking.hostName == "router" then "10.10.10.2" else "10.10.10.3";
in
{
  imports = [
    ../../../modules/nixos/router/common.nix
    ../../../modules/nixos/services/iventoy.nix
  ];

  # Recovery invariants: these assertions fail the build if the properties
  # that make the router usable in standby/dev mode are ever regressed.
  assertions = [
    {
      assertion =
        getAttrByPath [
          "systemd"
          "network"
          "networks"
          "20-router-lan"
          "networkConfig"
          "ConfigureWithoutCarrier"
        ] false config == true;
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
      assertion = config.systemd.services."serial-getty@ttyS0".enable;
      message = ''
        Router invariant violated: systemd.services."serial-getty@ttyS0".enable must be true.
        This provides the login prompt on the Proxmox serial terminal.
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

  services.router-ha = {
    enable = true;
    role = if config.networking.hostName == "router" then "master" else "backup";
    virtualIp = "10.10.10.1/16";
    vrrpInterface = lanDevice;
    keaSync.enable = true;
    keaSync.peerAddress =
      if config.networking.hostName == "router" then
        topology.backupHost.sshHostname
      else
        topology.routerHost.sshHostname;
    wan = {
      # The primary router must not let a transient VRRP FAULT during
      # nixos-rebuild switch take the live WAN interface down. Keep WAN
      # promotion hooks available on router-backup for dev/failover testing.
      enable = config.networking.hostName == "router-backup";
      interface = wanDevice;
      clonedMac = "02:76:c6:01:2a:b0";
    };
  };

  services.router-kea = {
    enable = true;
    dhcp4 = {
      interfaces = lib.mkForce [ lanDevice ];
      subnet = lanNetwork.cidr;
      gatewayAddress = lib.mkForce "10.10.10.1";
      dnsServers = lib.mkForce [ "10.10.10.1" ];
      poolRanges = lib.mkForce [
        {
          start = "10.10.10.100";
          end = "10.10.10.250";
        }
      ];
      ha = {
        enable = true;
        thisServerName = config.networking.hostName;
        role = if config.networking.hostName == "router" then "primary" else "secondary";
        peerAddress =
          if config.networking.hostName == "router" then
            topology.backupHost.sshHostname
          else
            topology.routerHost.sshHostname;
        peerName = if config.networking.hostName == "router" then "router-backup" else "router";
      };
      reservations = lib.mkForce (
        lib.mapAttrsToList (name: host: {
          hw-address = host.dhcpReservation.macAddress;
          ip-address = host.ip;
          hostname = name;
        }) reservableHosts
      );
    };
  };

  services.router-networking = {
    enable = true;
    wan = {
      device = wanDevice;
      macAddress = lib.mkIf (config.networking.hostName == "router") "02:76:c6:01:2a:b0";
    };
    routedInterfaces = {
      lan = {
        device = lanDevice;
        ipv4Address = if config.networking.hostName == "router" then "10.10.10.2/16" else "10.10.10.3/16";
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
        device = managementDevice;
        ipv4Address = managementIpv4Address;
        role = "management";
        prefixDelegationMode = "managed";
      };
    };
  };

  services.router-vpn = {
    enable = true;
    interfaces = {
      wg0 = {
        device = "wg0";
        ipv4Address = "10.0.0.2/32";
        privateKeyFile = "/var/lib/wireguard/private.key";
        policyRouting = {
          enable = true;
          table = 200;
        };
        peers = [
          {
            publicKey = "PLACEHOLDER_PUBLIC_KEY_1";
            endpoint = "vpn1.example.com:51820";
          }
        ];
      };
      wg1 = {
        device = "wg1";
        ipv4Address = "10.0.1.2/32";
        privateKeyFile = "/var/lib/wireguard/private_guest.key";
        policyRouting = {
          enable = true;
          table = 300;
        };
        peers = [
          {
            publicKey = "PLACEHOLDER_PUBLIC_KEY_2";
            endpoint = "vpn2.example.com:51820";
          }
        ];
      };
    };
  };

  services.router-optimizations = {
    enable = true;
    package = inputs.nix-router-optimized.packages.${pkgs.system}.router-diag;
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
        device = managementDevice;
        role = "management";
        label = "Management";
      };
    };
    conntrack-max = 262144;
  };

  services.router-technitium = {
    scopes.LAN = {
      enabled = false;
      legacyNames = [ "Default" ];
      startingAddress = "10.10.10.100";
      endingAddress = "10.10.10.250";
      subnetMask = "255.255.0.0";
      routerAddress = "10.10.10.1";
      domainName = topology.domain;
      domainSearchList = [ topology.domain ];
      useThisDnsServer = true;
      ntpServers = [ "10.10.10.1" ];
    };
    dhcpReservations = lib.mapAttrs (name: host: {
      scope = host.dhcpReservation.scope or "LAN";
      macAddress = host.dhcpReservation.macAddress;
      ipAddress = host.ip;
      hostName = name;
      comments = host.description or "";
    }) reservableHosts;
  };

  services.router-firewall = {
    enable = true;
    trustedTcpPorts = [
      80
      443
    ];
    hairpinNat.enable = true;
    trustedUdpPorts = [ ];
    extraLanLocalRules = ''
      tcp dport 5201 accept comment "iperf3 from LAN"
    '';
    flowLogging.enable = true;
  };

  # Fix: Technitium (bound to 0.0.0.0:53) sends UDP DNS replies from the
  # static LAN IP (10.10.10.2 / 10.10.10.3) instead of the VIP (10.10.10.1)
  # because the kernel's preferred source for the 10.10.0.0/16 route is the
  # statically-assigned address, not the keepalived VIP.  Clients that queried
  # 10.10.10.1 discard the reply because the source IP does not match.
  # This SNAT rule rewrites outbound DNS responses on the LAN interface so
  # they appear to originate from the VIP.  TCP is unaffected: the accepted
  # socket already binds to the VIP as its local address.
  networking.nftables.ruleset = lib.mkAfter ''
    table ip nat {
      chain dns-vip-snat {
        type nat hook output priority srcnat; policy accept;
        oifname "${lanDevice}" ip saddr ${staticLanIp} meta l4proto { tcp, udp } th sport 53 snat to ${topology.routerHost.ip}
      }
    }
  '';

  services.router-observability.enable = true;

  services.router-upnp.internalIPs = lib.mkForce [ lanDevice ];

  services.router-homelab.sshTarget = sshTarget;
  services.router-homelab.listenAddress = "0.0.0.0";

  services.router-dashboard = {
    refreshInterval = lib.mkDefault 10;
    interfaces = map (iface: {
      inherit (iface) device label;
      role = if iface.role == "management" then "mgmt" else iface.role;
    }) (lib.attrValues config.services.router-optimizations.interfaces);
    services = [
      "systemd-networkd"
      "sshd"
      "nftables"
      "caddy"
      "technitium-dns-server"
      "kea-dhcp4-server"
      "kea-dhcp-ddns-server"
      "miniupnpd"
      "tailscaled"
      "fail2ban"
      "prometheus"
      "grafana"
      "netdata"
      "router-dashboard"
      "health-mgmt-ip"
      "health-lan-ip"
      "health-wan-carrier"
      "health-wan-ip"
      "ulogd"
      "vector"
    ];
    links = lib.mkForce [
      {
        label = "Dashboard";
        url = "https://${mkFqdn "dashboard"}";
        icon = "🧭";
      }
      {
        label = "Grafana";
        url = "https://${mkFqdn "grafana"}";
        icon = "📈";
      }
      {
        label = "DNS Admin Mgmt";
        url = "http://${managementListenAddress}:5380/";
        icon = "🌍";
      }
      {
        label = "Prometheus Mgmt";
        url = "http://${managementListenAddress}:9090/";
        icon = "🎯";
      }
      {
        label = "Netdata Mgmt";
        url = "http://${managementListenAddress}:19999/";
        icon = "📊";
      }
      {
        label = "Dashboard Mgmt";
        url = "http://${managementListenAddress}:8888/";
        icon = "🧭";
      }
      {
        label = "DNS Admin LAN";
        url = "http://${lanListenAddress}:5380/";
        icon = "🌍";
      }
      {
        label = "Prometheus LAN";
        url = "http://${lanListenAddress}:9090/";
        icon = "🎯";
      }
      {
        label = "Netdata LAN";
        url = "http://${lanListenAddress}:19999/";
        icon = "📊";
      }
      {
        label = "Router SSH";
        kind = "copy";
        copyText = "ssh router";
        icon = "🖥️";
      }
      {
        label = "Backup SSH";
        kind = "copy";
        copyText = "ssh router-backup";
        icon = "🛟";
      }
      {
        label = "Router Mgmt";
        kind = "copy";
        copyText = topology.routerHost.sshHostname;
        icon = "🔧";
      }
      {
        label = "Backup Mgmt";
        kind = "copy";
        copyText = topology.backupHost.sshHostname;
        icon = "🧰";
      }
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

  # Keepalived enters FAULT if it starts before networkd has assigned the
  # physical LAN address. In HA mode that can leave the VIP absent, which makes
  # the LAN lose its default gateway during a rebuild.
  systemd.services.keepalived = {
    after = [
      "systemd-networkd.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    serviceConfig.ExecStartPre = [
      (pkgs.writeShellScript "keepalived-wait-for-lan-ip" ''
        set -eu
        for _ in $(seq 1 30); do
          if ${pkgs.iproute2}/bin/ip -4 addr show dev ${lanDevice} | ${pkgs.gnugrep}/bin/grep -q 'inet '; then
            exit 0
          fi
          ${pkgs.coreutils}/bin/sleep 1
        done
        echo "Timed out waiting for IPv4 address on ${lanDevice}" >&2
        exit 1
      '')
    ];
  };

  systemd.services.kea-dhcp4-server = {
    after = [ "technitium-sync-dhcp-scopes.service" ];
    wants = [ "technitium-sync-dhcp-scopes.service" ];
  };

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
  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty0"
  ];

  # Force serial getty to be active for recovery
  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  my.agenix.machineIdentity.enable = true;

  services.qemuGuest.enable = true;
  services.fstrim.enable = true;
  # NixOS's qemuGuest module only wires qemu-ga to a udev-triggered virtio-port
  # event. On Proxmox VMs that can leave the agent installed but never started,
  # so Proxmox reports the guest agent as missing after boot. Start it
  # explicitly as part of the normal boot target on router-class VMs.
  systemd.services.qemu-guest-agent.wantedBy = [ "multi-user.target" ];

  # Proxmox recovery path: keep a serial console available even when SSH or the
  # graphical console path is broken.
  # Legacy utmp bookkeeping is not useful on this appliance-style VM and
  # causes switch-to-configuration to fail noisily on Proxmox.
  systemd.services.systemd-update-utmp.enable = false;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    extraConfig = ''
      Match Address ${lanNetwork.cidr},${managementNetwork.cidr}
        PermitRootLogin prohibit-password
    '';
  };

  users.mutableUsers = false;

  users.users.root = {
    hashedPasswordFile = config.age.secrets.user-password-root.path;
    openssh.authorizedKeys.keys = [ operatorStableSshKey ];
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
    hashedPasswordFile = config.age.secrets.user-password-deepwatrcreatur.path;
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [ operatorStableSshKey ];
  };

  services.ssh-keys-manager.username = "deepwatrcreatur";

  programs.fish.enable = true;

  security.sudo.wheelNeedsPassword = false;

  # Emergency recovery: Auto-login root on the serial console ONLY for the backup router.
  services.getty.autologinUser = lib.mkIf (config.networking.hostName == "router-backup") "root";

  environment.systemPackages = with pkgs; [ tmux ];

  age.secrets = secrets.definitions // {
    user-password-root.file = ../../../secrets-agenix/user-password-root.age;
    user-password-deepwatrcreatur.file = ../../../secrets-agenix/user-password-deepwatrcreatur.age;
  };

  services.router-log-storage.enable = lib.mkForce enableLogStorage;

  # Explicit Health Model Services
  # These services exit with failure if the health invariant is violated,
  # allowing the dashboard's service monitor to surface interface-level health.
  #
  # RestartMode=direct is intentional here: during `nixos-rebuild switch`,
  # networkd briefly tears down and re-adds addresses/carrier state. Without
  # direct restarts, systemd records these health probes as failed units during
  # activation, which makes an otherwise healthy switch return non-zero.
  #
  # We still want sustained interface loss to remain visible as a restart loop,
  # but we do not want a transient network restart during activation to poison
  # the whole system switch result.
  systemd.services = {
    health-mgmt-ip = {
      description = "Health Check: Management IP Present";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c 'while true; do ${pkgs.iproute2}/bin/ip -4 addr show dev ${managementDevice} | ${pkgs.gnugrep}/bin/grep -q \"inet \" || exit 1; ${pkgs.coreutils}/bin/sleep 15; done'";
        Restart = "always";
        RestartMode = "direct";
        RestartSec = "15s";
      };
      wantedBy = [ "multi-user.target" ];
    };
    health-lan-ip = {
      description = "Health Check: Production LAN IP Present";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c 'while true; do ${pkgs.iproute2}/bin/ip -4 addr show dev ${lanDevice} | ${pkgs.gnugrep}/bin/grep -q \"inet \" || exit 1; ${pkgs.coreutils}/bin/sleep 15; done'";
        Restart = "always";
        RestartMode = "direct";
        RestartSec = "15s";
      };
      wantedBy = [ "multi-user.target" ];
    };
    health-wan-carrier = {
      description = "Health Check: WAN Carrier Active";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c 'while true; do ${pkgs.iproute2}/bin/ip -o link show dev ${wanDevice} | ${pkgs.gnugrep}/bin/grep -q \"LOWER_UP\" || exit 1; ${pkgs.coreutils}/bin/sleep 15; done'";
        Restart = "always";
        RestartMode = "direct";
        RestartSec = "15s";
      };
      wantedBy = [ "multi-user.target" ];
    };
    health-wan-ip = {
      description = "Health Check: WAN IP Present";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c 'while true; do ${pkgs.iproute2}/bin/ip -4 addr show dev ${wanDevice} | ${pkgs.gnugrep}/bin/grep -q \"inet \" || exit 1; ${pkgs.coreutils}/bin/sleep 15; done'";
        Restart = "always";
        RestartMode = "direct";
        RestartSec = "15s";
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Configure Technitium to accept RFC2136 dynamic DNS updates from Kea D2.
    # Registers the TSIG key and enables per-zone dynamic update permissions
    # for both the forward zone and the reverse zone.
    technitium-enable-rfc2136 = {
      description = "Configure Technitium RFC2136 dynamic update support for Kea DDNS";
      after = [
        "technitium-dns-server.service"
        "agenix.service"
      ];
      wants = [ "technitium-dns-server.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script =
        let
          apiKeyFile = secrets.path "technitium-api-key";
          tsigKeyFile = secrets.path "kea-ddns-tsig-key";
          fwdZone = topology.domain;
          revZone = "10.10.in-addr.arpa";
        in
        ''
          set -euo pipefail

          for i in {1..30}; do
            if ${pkgs.curl}/bin/curl -fsS http://127.0.0.1:5380/api/dns/status >/dev/null 2>&1; then
              break
            fi
            echo "Waiting for Technitium DNS Server to start..."
            ${pkgs.coreutils}/bin/sleep 2
          done

          TOKEN="$(${pkgs.coreutils}/bin/cat "${apiKeyFile}")"
          SECRET="$(${pkgs.coreutils}/bin/tr -d '\n' < "${tsigKeyFile}")"

          echo "Registering TSIG key kea-ddns in Technitium..."
          ${pkgs.curl}/bin/curl -fsS -X POST \
            -H "Content-Type: application/x-www-form-urlencoded" \
            --data-urlencode "token=$TOKEN" \
            --data-urlencode "tsigKeys=kea-ddns|$SECRET|hmac-sha256" \
            "http://127.0.0.1:5380/api/settings/set" \
            >/dev/null

          echo "Enabling RFC2136 updates for forward zone ${fwdZone}..."
          ${pkgs.curl}/bin/curl -fsS -X POST \
            -H "Content-Type: application/x-www-form-urlencoded" \
            --data-urlencode "token=$TOKEN" \
            --data-urlencode "zone=${fwdZone}" \
            --data-urlencode "update=AllowOnlySpecifiedNetworkAddresses" \
            --data-urlencode "updateNetworkACL=127.0.0.1" \
            "http://127.0.0.1:5380/api/zones/options/set" \
            >/dev/null

          echo "Enabling RFC2136 updates for reverse zone ${revZone}..."
          ${pkgs.curl}/bin/curl -fsS -X POST \
            -H "Content-Type: application/x-www-form-urlencoded" \
            --data-urlencode "token=$TOKEN" \
            --data-urlencode "zone=${revZone}" \
            --data-urlencode "update=AllowOnlySpecifiedNetworkAddresses" \
            --data-urlencode "updateNetworkACL=127.0.0.1" \
            "http://127.0.0.1:5380/api/zones/options/set" \
            >/dev/null

          echo "Technitium RFC2136 configuration applied"
        '';
    };
  };

  # nix-router-optimized currently writes `global.loglevel` into the ulogd
  # config file, but ulogd 2.0.9 rejects that key. Keep the service-level
  # logLevel, but override the generated config to omit the invalid entry.
  # Also align plugins with what is actually shipped in pkgs.ulogd.
  services.ulogd.settings = lib.mkForce {
    global = {
      logfile = "/var/log/ulogd/ulogd.log";
      plugin = [
        "${pkgs.ulogd}/lib/ulogd/ulogd_inppkt_NFLOG.so"
        "${pkgs.ulogd}/lib/ulogd/ulogd_raw2packet_BASE.so"
        "${pkgs.ulogd}/lib/ulogd/ulogd_filter_IFINDEX.so"
        "${pkgs.ulogd}/lib/ulogd/ulogd_filter_IP2STR.so"
        "${pkgs.ulogd}/lib/ulogd/ulogd_filter_PRINTPKT.so"
        "${pkgs.ulogd}/lib/ulogd/ulogd_output_LOGEMU.so"
      ];
      stack = "log1:NFLOG,base1:BASE,ifi1:IFINDEX,ip2str1:IP2STR,print1:PRINTPKT,emu1:LOGEMU";
    };
    log1 = {
      group = 1;
    };
    emu1 = {
      file = "/var/log/ulogd/flow.log";
      sync = 1;
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
