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
      sshTarget = "ssh router-backup";
      wanDevice = "enp2s0";
      lanDevice = "enp3s0";
      lanIpv4Address = "${routerHost.ip}/${toString lanNetwork.prefixLength}";
      managementIpv4Address = "${backupHost.sshHostname}/${toString managementNetwork.prefixLength}";
      grafanaDomain = mkFqdn "grafana";
      grafanaDataDir = "/var/log/router-backup/grafana";
      prometheusStateDir = "router-backup-prometheus";
      prometheusBindMountPath = "/var/log/router-backup/prometheus";
      enableLogStorage = false;
    })
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  # Pin the physical passthrough NICs to stable names via PCI path-based udev
  # rules. Unlike the primary router (where we use MAC matching), the backup
  # router's PCIe slot layout is the primary stable identifier.
  # The management virtio NIC (ens18) is already stable and does not need a rule.
  systemd.network.links = {
    "10-router-backup-lan-stable" = {
      matchConfig.Path = "pci-0000:03:00.0";
      linkConfig.Name = "enp3s0";
    };
    "10-router-backup-wan-stable" = {
      matchConfig.Path = "pci-0000:02:00.0";
      linkConfig.Name = "enp2s0";
    };
  };

  home-manager.extraSpecialArgs.hostName = lib.mkForce "router-backup";
}
