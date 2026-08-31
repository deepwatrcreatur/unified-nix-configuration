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
  enableExtraRoutedNetworks ? false,
  enableLogStorage ? true,
  enableHa ? true,
  ownLanServices ? true,
  enableNetworkSecurity ? ownLanServices,
  enableWanHa ? true,
  requireWanOnline ? enableWanHa,
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
  keaDhcp4LeaseHeader =
    "address,hwaddr,client_id,valid_lifetime,expire,subnet_id,fqdn_fwd,fqdn_rev,hostname,state,user_context,pool_id";
  ensureKeaLeaseState = pkgs.writeShellScript "router-kea-ensure-state" ''
    set -euo pipefail

    install -d -m 0750 -o kea -g kea /var/lib/private/kea

    expected_header='${keaDhcp4LeaseHeader}'

    for lease_file in /var/lib/private/kea/dhcp4.leases /var/lib/private/kea/dhcp4.leases.2; do
      if [ ! -e "$lease_file" ]; then
        : > "$lease_file"
      fi

      if [ -s "$lease_file" ]; then
        header="$(head -n 1 "$lease_file" || true)"
        if [ "$header" != "$expected_header" ]; then
          backup="$lease_file.incompatible.$(date +%s)"
          cp -a "$lease_file" "$backup"
          : > "$lease_file"
          echo "router-kea-ensure-state: reset incompatible lease file header in $lease_file (backup: $backup)" >&2
        fi

        if ${pkgs.gawk}/bin/gawk -F, '$10 == "1" { exit 0 } END { exit 1 }' "$lease_file" 2>/dev/null; then
          temp_clean="$lease_file.clean.$(date +%s)"
          ${pkgs.gawk}/bin/gawk -F, 'NR==1 || $10 != "1"' "$lease_file" > "$temp_clean" || true
          cat "$temp_clean" > "$lease_file"
          rm -f "$temp_clean"
          echo "router-kea-ensure-state: purged declined leases from $lease_file" >&2
        fi
      fi

      chown kea:kea "$lease_file"
      chmod 0640 "$lease_file"
    done

    find /var/lib/private/kea -name "dhcp4.leases.incompatible.*" -mtime +1 -delete 2>/dev/null || true
  '';
  waitForKeaLanReady = pkgs.writeShellScript "router-kea-wait-for-lan-ready" ''
    set -euo pipefail

    iface=${lib.escapeShellArg lanDevice}
    expected_ipv4=${lib.escapeShellArg staticLanIp}
    SECONDS=0

    while [ "$SECONDS" -lt 30 ]; do
      if ${pkgs.iproute2}/bin/ip -o link show dev "$iface" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "LOWER_UP" \
        && ${pkgs.iproute2}/bin/ip -o -4 addr show dev "$iface" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q " $expected_ipv4/"; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done

    echo "router-kea: LAN interface $iface was not carrier-up with IPv4 $expected_ipv4 within 30 seconds" >&2
    exit 1
  '';

  secrets = optSec.mkSecrets {
    user-password-deepwatrcreatur = {
      file = ../../../secrets-agenix/user-password-deepwatrcreatur.age;
    };
    user-password-root = {
      file = ../../../secrets-agenix/user-password-root.age;
    };
    cloudflare-api-key = {
      file = ../../../secrets-agenix/cloudflare_ddns_API_token.age;
      group = "router-dashboard";
      mode = "0440";
    };
    technitium-api-key = {
      file = ../../../secrets-agenix/technitium-api-key.age;
      mode = "0444";
    };
    technitium-admin-password = {
      file = ../../../secrets-agenix/technitium-admin-password.age;
      mode = "0400";
    };
    kea-ddns-tsig-key =
      {
        file = ../../../secrets-agenix/kea-ddns-tsig-key.age;
        mode = "0440";
      }
      // lib.optionalAttrs ownLanServices {
        group = "kea";
      };
    tailscale-auth-key = {
      file = ../../../secrets-agenix/tailscale-auth-key.age;
    };
  };

  topology = config.router.topology;
  iventoy = config.services.iventoy;
  lanNetwork = topology.networks.lan;
  managementNetwork = topology.networks.management;
  mkFqdn = label: "${label}.${topology.domain}";
  isPrimaryRouter = config.networking.hostName == "router";
  routerHaRoleFile = "/run/router-ha/role";
  masterExecCondition =
    "${pkgs.runtimeShell} -c '[ \"$(cat ${routerHaRoleFile} 2>/dev/null || true)\" = master ]'";
  wanRequiredForOnline = if requireWanOnline then "routable" else "no";
  singleActiveLanUnits =
    [
      "inadyn.service"
      "kea-dhcp4-server.service"
      "kea-dhcp-ddns-server.service"
      "miniupnpd.service"
      "router-ipv6-ra-owner.service"
    ]
    ++ lib.optional (config.services.router-ddns.enable or false) "inadyn.timer";
  ipv6RaOwnerDropInDir = "/run/systemd/network/08-router-parent-${lanDevice}.network.d";
  ipv6RaOwnerDropIn = "${ipv6RaOwnerDropInDir}/90-router-ha-ra.conf";
  enableIpv6RaOwner = pkgs.writeShellScript "router-ipv6-ra-owner-enable" ''
    set -euo pipefail
    install -d -m 0755 ${lib.escapeShellArg ipv6RaOwnerDropInDir}
    cat > ${lib.escapeShellArg ipv6RaOwnerDropIn} <<'EOF'
    [Network]
    IPv6SendRA=true
    EOF
    ${pkgs.systemd}/bin/networkctl reload
    ${pkgs.systemd}/bin/networkctl reconfigure ${lib.escapeShellArg lanDevice}
  '';
  disableIpv6RaOwner = pkgs.writeShellScript "router-ipv6-ra-owner-disable" ''
    set -euo pipefail
    rm -f ${lib.escapeShellArg ipv6RaOwnerDropIn}
    ${pkgs.systemd}/bin/networkctl reload
    ${pkgs.systemd}/bin/networkctl reconfigure ${lib.escapeShellArg lanDevice}
  '';
  # Static LAN IP assigned to this router node, distinct from the shared VIP.
  staticLanIp = builtins.head (lib.splitString "/" lanIpv4Address);
  reservableHosts = lib.filterAttrs (
    _name: host: (host.dhcpReservation or null) != null && (host.ip or null) != null
  ) topology.hosts;
  poolRangeKeys = map (pool: "${pool.start}-${pool.end}") config.services.router-kea.dhcp4.poolRanges;
in
{
  imports = [
    ../../../modules/nixos/router/common.nix
    ../../../modules/nixos/router/snmp.nix
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
      assertion = lib.length poolRangeKeys == lib.length (lib.unique poolRangeKeys);
      message = ''
        Router invariant violated: services.router-kea.dhcp4.poolRanges contains duplicate ranges.
        This usually means more than one module is defining the same LAN DHCP pool, which causes
        Kea to fail at startup with an overlapping-pool parser error.
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

  services.router-ha =
    lib.mkIf enableHa
      {
        # Both router nodes participate in VRRP so LAN VIP and WAN ownership can
        # move together during failover.
        enable = true;
        role = if isPrimaryRouter then "master" else "backup";
        virtualIp = "10.10.10.1/16";
        vrrpInterface = lanDevice;
        singleActiveUnits = singleActiveLanUnits;
        keaSync.enable = isPrimaryRouter;
        keaSync.peerAddress = if isPrimaryRouter then "10.10.11.213" else "10.10.11.1"; # Using management IPs for control plane sync
        wan = {
          # Public ingress failover requires WAN ownership to follow VRRP
          # promotion, not just the LAN VIP.
          enable = enableWanHa;
          interface = wanDevice;
          clonedMac = "02:76:c6:01:2a:b0";
        };
      };

  services.router-dns-service.serviceListenAddresses = lib.mkIf (!enableHa && ownLanServices) (
    lib.mkForce [
      "127.0.0.1"
      lanListenAddress
    ]
  );

  services.router-ddns = {
    enable = lib.mkForce ownLanServices;
  }
  // lib.optionalAttrs ownLanServices {
    cloudflare = {
      zoneName = topology.domain;
      labels = topology.routerHost.ddnsServices;
      apiTokenFile = config.age.secrets.cloudflare-api-key.path;
    };
  };

  services.router-kea = {
    # In non-HA mode, the primary router owns DHCP directly. The backup keeps
    # Kea disabled so it remains a cold/manual spare instead of racing the
    # production router during boot or recovery.
    enable = lib.mkForce ownLanServices;
  }
  // lib.optionalAttrs ownLanServices {
    dhcp4 = {
      interfaces = [ lanDevice ];
      subnet = lanNetwork.cidr;
      gatewayAddress = "10.10.10.1";
      dnsServers = [ "10.10.10.1" ];
      poolRanges = [
        {
          # Keep dynamic leases away from the low/static part of the /16 and
          # avoid .0/.255 boundaries in each /24-sized slice.
          start = "10.10.200.1";
          end = "10.10.222.254";
        }
      ];
      ha = {
        # DHCP HA is still a client-path regression: the primary can come up in
        # WAITING with local DHCP disabled until the backup peer times out.
        enable = false;
        thisServerName = config.networking.hostName;
        role = if isPrimaryRouter then "primary" else "secondary";
        peerAddress = if isPrimaryRouter then "10.10.11.213" else "10.10.11.1";
        peerName = if isPrimaryRouter then "router-backup" else "router";
      };
      pxe = {
        enable = true;
        bootServerAddress = topology.routerHost.ip;
        bootServerName = mkFqdn "router";
        # iVentoy external mode expects this loader name and serves the real
        # BIOS/UEFI path after inspecting the DHCP request.
        bootFilename = "iventoy_loader_${toString iventoy.httpPort}";
      };
      reservations = lib.mapAttrsToList (name: host: {
        hw-address = host.dhcpReservation.macAddress;
        ip-address = host.ip;
        hostname = name;
      }) reservableHosts;
    };

    ddns = {
      enable = true;
      tsigKeyFile = config.age.secrets.kea-ddns-tsig-key.path;
      tsigKeyName = "kea-ddns";
      forwardZone = topology.domain;
      reverseZone = "10.10.in-addr.arpa";
    };
  };

  services.router-upnp = {
    # In HA mode the promoted node owns miniupnpd at runtime. In the current
    # simplified consumer mode, only the primary router exposes UPnP/NAT-PMP.
    enable = lib.mkForce ownLanServices;
    externalInterface = wanDevice;
    internalIPs = [ lanDevice ];
  };

  services.kea.dhcp4.settings = lib.mkIf ownLanServices {
    valid-lifetime = lib.mkForce 14400; # 4 hours (down from 24h) to recycle abandoned leases quickly
    renew-timer = lib.mkForce 3600; # 1 hour renewal for active clients
    rebind-timer = lib.mkForce 7200; # 2 hour rebind
    decline-probation-period = lib.mkForce 300; # 5 minutes runtime probation for DECLINED leases (down from 24h)
    match-client-id = lib.mkForce false; # Match strictly by physical MAC address, preventing client-id churn pool bloat
    host-reservation-identifiers = lib.mkForce [ "hw-address" ];
    expired-leases-processing = {
      reclaim-timer-wait-time = 10;
      flush-reclaimed-timer-wait-time = 25;
      hold-reclaimed-time = 300; # 5 minutes (down from 1 hour) before reclaimed leases re-enter free pool
      max-reclaim-leases = 100;
      max-reclaim-time = 250;
    };
  };

  # Keep Chrony available on both router nodes. Upstream explicitly leaves NTP
  # ownership as consumer policy, and this deployment wants standby time sync
  # continuity rather than a single-owner Chrony model.
  services.router-ntp.enable = true;

  systemd.services.kea-dhcp4-server = lib.mkMerge [
    (lib.mkIf ownLanServices {
      serviceConfig.ExecStartPre = lib.mkBefore [
        "+${ensureKeaLeaseState}"
        "+${waitForKeaLanReady}"
      ];
    })
    (lib.mkIf enableHa {
      wantedBy = lib.mkForce [ ];
      serviceConfig.ExecCondition = lib.mkBefore [
        masterExecCondition
      ];
      after = [ "router-ha-initial-role-state.service" ];
      requires = [ "router-ha-initial-role-state.service" ];
    })
  ];
  systemd.services.kea-dhcp-ddns-server = lib.mkIf enableHa {
    wantedBy = lib.mkForce [ ];
    serviceConfig.ExecCondition = lib.mkBefore [
      masterExecCondition
    ];
    after = [ "router-ha-initial-role-state.service" ];
    requires = [ "router-ha-initial-role-state.service" ];
  };
  systemd.services.inadyn = lib.mkIf enableHa {
    after = [ "router-ha-initial-role-state.service" ];
    requires = [ "router-ha-initial-role-state.service" ];
    wantedBy = lib.mkForce [ ];
    serviceConfig.ExecCondition = lib.mkBefore [
      masterExecCondition
    ];
  };
  systemd.timers.inadyn.wantedBy = lib.mkIf enableHa (lib.mkForce [ ]);
  systemd.services.miniupnpd = lib.mkIf enableHa {
    after = [ "router-ha-initial-role-state.service" ];
    requires = [ "router-ha-initial-role-state.service" ];
    wantedBy = lib.mkForce [ ];
    serviceConfig.ExecCondition = lib.mkBefore [
      masterExecCondition
    ];
  };
  systemd.services.router-ipv6-ra-owner = lib.mkIf enableHa {
    description = "Apply IPv6 RA ownership to the active router";
    after = [ "router-ha-initial-role-state.service" ];
    requires = [ "router-ha-initial-role-state.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecCondition = [ masterExecCondition ];
      ExecStart = [ "+${enableIpv6RaOwner}" ];
      ExecStop = [ "+${disableIpv6RaOwner}" ];
    };
  };

  services.router-networking = {
    enable = true;
    wan = {
      device = wanDevice;
      requiredForOnline = wanRequiredForOnline;
    };
    routedInterfaces =
      {
        lan = {
          device = lanDevice;
          ipv4Address =
            if !enableHa then
              lanIpv4Address
            else if config.networking.hostName == "router" then
              "10.10.10.2/16"
            else
              "10.10.10.3/16";
          dns = [ "127.0.0.1" ];
          domains = [ topology.domain ];
          requiredForOnline = "no";
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
          requiredForOnline = "carrier";
          prefixDelegationMode = "managed";
        };
      }
      // lib.optionalAttrs enableExtraRoutedNetworks {
        iot = {
          device = "${lanDevice}.20";
          vlanId = 20;
          parentDevice = lanDevice;
          ipv4Address = "10.20.20.1/24";
          policyRouting = {
            enable = true;
            table = 200; # All traffic via table 200 (VPN)
          };
        };
        guest = {
          device = "${lanDevice}.30";
          vlanId = 30;
          parentDevice = lanDevice;
          ipv4Address = "10.30.30.1/24";
          policyRouting = {
            # Use default routing (WAN) by default
            enable = false;
            # But route traffic to 8.8.8.8 via table 300 (VPN)
            rules = [
              {
                to = "8.8.8.8/32";
                table = 300;
                priority = 50;
              }
            ];
          };
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
    package = inputs.nix-router-optimized.packages.${pkgs.stdenv.hostPlatform.system}.router-diag;
    interfaces =
      {
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
      }
      // lib.optionalAttrs enableExtraRoutedNetworks {
        iot = {
          device = "${lanDevice}.20";
          role = "lan";
          label = "IoT VLAN";
        };
        guest = {
          device = "${lanDevice}.30";
          role = "lan";
          label = "Guest VLAN";
        };
      };
    conntrack-max = 262144;
  };

  services.router-technitium = {
    bootstrapPasswordSecretName = "technitium-admin-password";
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
    flowtable.sipFriendly.enable = true;
    trustedUdpPorts = [ ];
    extraLanLocalRules = ''
      tcp dport 5201 accept comment "iperf3 from LAN"
    '';
    flowLogging.enable = true;
  };

  services.router-observability.enable = true;

  services.router-pangolin = {
    enable = true;
    openFirewall = true;
  };

  services.router-network-security = {
    enable = enableNetworkSecurity;
    interfaces = [ lanDevice ];
    suricata = {
      enable = enableNetworkSecurity;
      evebox.enable = enableNetworkSecurity;
    };
  };

  services.router-snmp = {
    enable = true;
    listenAddresses = [
      "127.0.0.1"
      managementListenAddress
    ] ++ lib.optionals ownLanServices [ "10.10.10.1" ];
  };

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
      "snmpd"
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
    ] ++ lib.optionals enableNetworkSecurity [
      "suricata"
      "router-evebox"
    ];
    links = lib.mkForce (
      [
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
      ]
      ++ lib.optionals enableNetworkSecurity [
        {
          label = "EveBox";
          url = "https://${mkFqdn "evebox"}";
          icon = "🔎";
        }
      ]
      ++ [
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
      ]
    );
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
    alerting.enable = true;
  };

  services.netdata.config.global."bind to" = "0.0.0.0";

  # Router hosts already render /etc/resolv.conf declaratively from NixOS
  # networking settings, so the legacy resolvconf manager must stay disabled on
  # 26.05 to avoid conflicting ownership of that path.
  networking.resolvconf.enable = lib.mkForce false;

  # Keep the production LAN address present even when the data-plane cable is
  # intentionally unplugged on a standby/dev router. That allows dashboard and
  # router-role services to come up in a degraded-but-testable state.
  systemd.network.networks."20-router-lan".networkConfig.ConfigureWithoutCarrier = true;
  systemd.network.networks."20-router-lan".linkConfig.RequiredForOnline = lib.mkForce "no";

  # Make network-online.target wait for the interfaces that matter on each
  # node. The primary should wait for WAN before WAN-dependent services start,
  # while the WAN-less backup should only wait for the management plane.
  systemd.network.wait-online.anyInterface = lib.mkForce false;

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
  # NixOS's qemuGuest module only wires qemu-ga to a udev-triggered virtio-port
  # event. On Proxmox VMs that can leave the agent installed but never started,
  # so Proxmox reports the guest agent as missing after boot. Start it
  # explicitly as part of the normal boot target on router-class VMs.
  systemd.services.qemu-guest-agent.wantedBy = [ "multi-user.target" ];

  # Proxmox recovery path: keep a serial console available even when SSH or the
  # graphical console path is broken.
  systemd.services."serial-getty@ttyS0".enable = true;
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
    hashedPasswordFile = config.age.secrets.user-password-deepwatrcreatur.path;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [ operatorStableSshKey ];
  };

  services.ssh-keys-manager.username = "deepwatrcreatur";

  programs.fish.enable = true;

  security.sudo.wheelNeedsPassword = false;

  # Emergency recovery: Auto-login root on the serial console ONLY for the backup router.
  services.getty.autologinUser = lib.mkIf (config.networking.hostName == "router-backup") "root";

  environment.systemPackages = with pkgs; [ tmux ];

  age.secrets = secrets.definitions;

  services.router-log-storage.enable = lib.mkForce enableLogStorage;

  # UDP replies sourced from the node-local LAN address confuse clients that
  # sent their DNS query to the shared VIP. Rewrite only DNS replies headed
  # back onto the LAN so they appear to originate from the VIP.
  networking.nftables.ruleset = lib.mkAfter ''
    table ip nat {
      chain dns-vip-snat {
        type nat hook postrouting priority 100; policy accept;
        oifname "${lanDevice}" ip saddr ${staticLanIp} udp sport 53 snat to ${topology.routerHost.ip}
      }
    }
  '';

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

  # The upstream router-networking module currently emits both:
  # - 08-router-parent-${lanDevice}.network
  # - 20-router-lan.network
  #
  # Because systemd-networkd applies the first matching .network file, the
  # parent VLAN file wins and the later LAN file never assigns the production
  # LAN address. Keep the active parent file carrying the LAN L3 config until
  # the upstream module is corrected.
  systemd.network.networks."08-router-parent-${lanDevice}" = {
    address = [ lanIpv4Address ];
    routes = [
      {
        Destination = lanNetwork.cidr;
        Scope = "link";
      }
    ];
    networkConfig = {
      VLAN = [
        "${lanDevice}.20"
        "${lanDevice}.30"
      ];
      ConfigureWithoutCarrier = true;
      DHCPPrefixDelegation = true;
      DHCPServer = false;
      DNS = [ "127.0.0.1" ];
      Domains = [ topology.domain ];
      IPv6PrivacyExtensions = "no";
      IPv6SendRA = !enableHa && ownLanServices;
    };
    linkConfig.RequiredForOnline = lib.mkForce "no";
    ipv6SendRAConfig = {
      EmitDNS = true;
      Managed = false;
      OtherInformation = false;
    };
    ipv6Prefixes = [
      {
        Prefix = "::/64";
        PreferredLifetimeSec = 1800;
        ValidLifetimeSec = 3600;
      }
    ];
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
