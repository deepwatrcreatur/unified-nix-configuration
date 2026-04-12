{
  config,
  lib,
  inputs,
  ...
}:
let
  topology = config.router.topology;
  routerHost = topology.routerHost;
  backupHost = topology.backupHost;
  domain = topology.domain;
  lanNetwork = topology.networks.lan;
  managementNetwork = topology.networks.management;
  lanIpv4Address = "${routerHost.ip}/${toString lanNetwork.prefixLength}";
  managementIpv4Address = "${routerHost.sshHostname}/${toString managementNetwork.prefixLength}";
  mkFqdn = label: "${label}.${domain}";
in
{
  imports = [
    (import ./role.nix {
      inherit inputs;
      sshTarget = "ssh router";
      wanDevice = "enp6s17";
      lanDevice = "enp6s16";
      inherit lanIpv4Address managementIpv4Address;
      grafanaDomain = mkFqdn "grafana";
      grafanaDataDir = "/var/log/router/grafana";
      prometheusStateDir = "router-prometheus";
      prometheusBindMountPath = "/var/log/router/prometheus";
    })
  ];

  fileSystems."/srv/pxe" = {
    device = "/dev/disk/by-partlabel/disk-pxe-images-images";
    fsType = "ext4";
    options = [
      "noatime"
      "nofail"
      "x-systemd.automount"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/pxe 0755 root root -"
  ];

  systemd.services.setup-router-pxe-storage = {
    description = "Prepare router PXE storage directories";
    after = [ "srv-pxe.mount" ];
    wants = [ "srv-pxe.mount" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /srv/pxe/images
      mkdir -p /srv/pxe/ipxe
      chmod 0755 /srv/pxe /srv/pxe/images /srv/pxe/ipxe
    '';
  };

  # Stable NIC identity via systemd .link files.
  #
  # Physical passthrough NICs are pinned by MAC so that PCI slot renumbering
  # (e.g. after adding/removing a Proxmox device) does not silently break
  # interface-name assumptions in role.nix.
  #
  # Mapping confirmed from live router VM inspection:
  #   enp6s16  LAN   igc   pci-0000:06:10.0   MAC 02:76:c6:01:2a:af
  #   enp6s17  WAN   igc   pci-0000:06:11.0   MAC 02:76:c6:01:2a:b0
  #   ens18    mgmt  virtio (Proxmox virtio slot; virtio slot naming already stable)
  systemd.network.links = {
    "10-router-lan-stable" = {
      matchConfig.MACAddress = "02:76:c6:01:2a:af";
      linkConfig.Name = "enp6s16";
    };
    "10-router-wan-stable" = {
      matchConfig.MACAddress = "02:76:c6:01:2a:b0";
      linkConfig.Name = "enp6s17";
    };
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
        nameserverIP = zone.nameserverIP or routerHost.ip;
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

}
