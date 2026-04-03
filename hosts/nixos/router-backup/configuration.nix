{ lib, inputs, ... }:
let
  hostsData = import ../../../lib/hosts.nix;
  routerHost = hostsData.hosts.router;
  backupHost = hostsData.hosts.router-backup;
in
{
  imports = [
    (import ../router/role.nix {
      sshTarget = "ssh router-backup.deepwatercreature.com";
      wanDevice = "enp2s0";
      lanDevice = "enp3s0";
      lanIpv4Address = "${routerHost.ip}/16";
      managementIpv4Address = "${backupHost.sshHostname}/24";
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
