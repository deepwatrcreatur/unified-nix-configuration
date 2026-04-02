{ lib, inputs, ... }:
{
  imports = [
    (import ../router/role.nix {
      sshTarget = "ssh router-backup.deepwatercreature.com";
      wanDevice = "enp2s0";
      lanDevice = "enp3s0";
      managementIpv4Address = "192.168.100.99/24";
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
