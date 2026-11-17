# elitedesk: bare-metal router host, joining as a standby next to `router`.
#
# It runs the full router role with LAN services off (ownLanServices = false):
# no DHCP, DDNS, UPnP or IPv6 RA, so it cannot fight the live router while
# both are cabled. Promotion to primary is a separate, deliberate change; see
# docs/design/router-election/README.md.
#
# NICs (pinned by MAC below):
#   eno1      82579LM onboard 1G   management, 192.168.100.98
#   enp1s0f0  X520 port 0 (SFP+)   WAN  - currently the 10G-SR optic
#   enp1s0f1  X520 port 1 (SFP+)   LAN  - currently the DAC to the switch
# Swap the two X520 MACs below if the cabling ends up the other way round.
{
  config,
  lib,
  inputs,
  ...
}:
let
  topology = config.router.topology;
  lanNetwork = topology.networks.lan;
  managementNetwork = topology.networks.management;
  # Standby LAN address. 10.10.10.3 (router-backup's) is still held by the old
  # router-backup VM; 10.10.10.4 was free on 2026-11-17.
  standbyLanIp = "10.10.10.4";
  mkFqdn = label: "${label}.${topology.domain}";
in
{
  imports = [
    (import ../router/role.nix {
      inherit inputs;
      sshTarget = "ssh elitedesk";
      enableHa = false;
      # INVARIANT: false while `router` is primary. Turning this on starts
      # Kea, DDNS, UPnP and RA on the LAN.
      ownLanServices = false;
      enableNetworkSecurity = false;
      enableWanHa = false;
      requireWanOnline = false;
      wanDevice = "enp1s0f0";
      lanDevice = "enp1s0f1";
      managementDevice = "eno1";
      wanBandwidth = "2.5Gbit";
      lanIpv4Address = "${standbyLanIp}/${toString lanNetwork.prefixLength}";
      managementIpv4Address = "${topology.hosts.elitedesk.sshHostname}/${toString managementNetwork.prefixLength}";
      grafanaDomain = mkFqdn "grafana";
      grafanaDataDir = "/var/log/router/grafana";
      prometheusStateDir = "router-prometheus";
      prometheusBindMountPath = "/var/log/router/prometheus";
    })
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  systemd.network.links = {
    "10-elitedesk-wan-stable" = {
      matchConfig.MACAddress = "90:e2:ba:7f:e0:3c";
      linkConfig.Name = "enp1s0f0";
    };
    "10-elitedesk-lan-stable" = {
      matchConfig.MACAddress = "90:e2:ba:7f:e0:3d";
      linkConfig.Name = "enp1s0f1";
    };
    "10-elitedesk-mgmt-stable" = {
      matchConfig.MACAddress = "24:be:05:06:9b:09";
      linkConfig.Name = "eno1";
    };
  };

  # WHY: a second Tailscale node with router's routes would advertise the same
  # subnets; enable it at promotion.
  host.networking.enableTailscale = lib.mkForce false;
  services.router-tailscale.enable = lib.mkForce false;

  # Gate management-plane readiness on wait-online, as router-backup did.
  systemd.network.wait-online.enable = lib.mkForce true;

  # GOTCHA: a standby with no WAN must not send RAs or request prefix
  # delegation, or LAN clients get a second default route that blackholes.
  services.router-networking.routedInterfaces = {
    lan = {
      ipv6SendRA = false;
      dhcpPrefixDelegation = false;
    };
    management = {
      ipv6SendRA = false;
      dhcpPrefixDelegation = false;
    };
  };

  # INVARIANT: WAN stays administratively down on the standby. With DHCP on,
  # it would ask the cable modem for a lease and could take the WAN address
  # from the live router (many modems hand out only one). Remove at promotion.
  systemd.network.networks."10-router-wan-primary".linkConfig.ActivationPolicy = "down";

  # WHY: two mDNS reflectors bridging the same LAN and management segments
  # duplicate announcements; only the active router reflects.
  services.router-mdns.enable = lib.mkForce false;

  systemd.services = {
    health-wan-carrier.enable = lib.mkForce false;
    health-wan-ip.enable = lib.mkForce false;
  };

  # Keep DNS running on standby, but no DHCP scopes, reservations or NTP
  # changes pushed into the local Technitium.
  services.router-technitium = {
    scopes = lib.mkForce { };
    dhcpReservations = lib.mkForce { };
    ntpServers = lib.mkForce [ ];
    forceBlockListUpdateOnActivation = lib.mkForce false;
  };

  # Logs partition is XFS on this host (see disko.nix); router's is ext4.
  services.router-log-storage.fsType = "xfs";

  fileSystems."/srv/pxe" = {
    device = "/dev/disk/by-partlabel/disk-pxe-images-images";
    fsType = "ext4";
    options = [ "noatime" "nofail" "x-systemd.automount" ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/pxe 0755 root root -"
  ];

  # PXE config stays in tree; iVentoy would answer PXE on the LAN, so it only
  # runs on the active router.
  services.iventoy = {
    enable = lib.mkForce false;
    isoDir = "/srv/pxe/images";
    openFirewall = false;
  };

  services.router-firewall = {
    trustedTcpPorts = [ 16000 26000 ];
    trustedUdpPorts = [ 69 4011 ];
  };
}
