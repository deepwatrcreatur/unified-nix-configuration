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
  mkFqdn = label: "${label}.${domain}";
in
{
  imports = [
    (import ../router/role.nix {
      inherit inputs;
      sshTarget = "ssh router-backup";
      wanDevice = "enp2s0";
      lanDevice = "enp3s0";
      lanIpv4Address = "${routerHost.ip}/${toString lanNetwork.prefixLength}";
      managementIpv4Address = "${backupHost.sshHostname}/${toString managementNetwork.prefixLength}";
      grafanaDomain = mkFqdn "grafana";
      grafanaDataDir = "/var/log/router-backup/grafana";
      prometheusStateDir = "router-backup-prometheus";
      prometheusBindMountPath = "/var/log/router-backup/prometheus";
    })
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  services.router-log-storage.mountPoint = lib.mkForce "/var/log/router-backup";

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

  systemd.services.setup-router-backup-pxe-storage = {
    description = "Prepare router-backup PXE storage directories";
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

  services.iventoy = {
    enable = true;
    isoDir = "/srv/pxe/images";
    openFirewall = false;
  };

  services.router-firewall = {
    trustedTcpPorts = [
      16000
      26000
    ];
    trustedUdpPorts = [
      69
      4011
    ];
  };

  # Pin the physical passthrough NICs to stable names via MAC matching.
  # Mapping confirmed from VM inspection:
  #   enp3s0 (LAN) -> 6c:b3:11:1b:97:38
  #   enp2s0 (WAN) -> 6c:b3:11:1b:97:39
  systemd.network.links = {
    "10-router-backup-lan-stable" = {
      matchConfig.MACAddress = "6c:b3:11:1b:97:38";
      linkConfig.Name = "enp3s0";
    };
    "10-router-backup-wan-stable" = {
      matchConfig.Path = "pci-0000:03:00.1";
      linkConfig.Name = "enp2s0";
    };
  };

  home-manager.extraSpecialArgs.hostName = lib.mkForce "router-backup";


}
