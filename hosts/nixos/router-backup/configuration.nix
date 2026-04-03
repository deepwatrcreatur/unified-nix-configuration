{ lib, inputs, ... }:
let
  hostsData = import ../../../lib/hosts.nix;
  routerHost = hostsData.hosts.router;
  backupHost = hostsData.hosts.router-backup;
  lanNetwork = hostsData.networks.lan;
  managementNetwork = hostsData.networks.management;
in
{
  imports = [
    (import ../router/role.nix {
      sshTarget = "ssh router-backup.deepwatercreature.com";
      wanDevice = "enp2s0";
      lanDevice = "enp3s0";
      lanIpv4Address = "${routerHost.ip}/${toString lanNetwork.prefixLength}";
      managementIpv4Address = "${backupHost.sshHostname}/${toString managementNetwork.prefixLength}";
      grafanaDomain = "router-backup.deepwatercreature.com";
      grafanaDataDir = "/var/log/router-backup/grafana";
      prometheusStateDir = "router-backup-prometheus";
      prometheusBindMountPath = "/var/log/router-backup/prometheus";
      enableLogStorage = false;
    })
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  home-manager.extraSpecialArgs.hostName = lib.mkForce "router-backup";
}
