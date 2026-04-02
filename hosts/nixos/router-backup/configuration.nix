{ lib, inputs, ... }:
{
  imports = [
    ../router/configuration.nix
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  home-manager.extraSpecialArgs.hostName = lib.mkForce "router-backup";

  services.router-homelab.sshTarget = lib.mkForce "ssh router-backup.deepwatercreature.com";


  router.monitoring = {
    grafanaDomain = lib.mkForce "router-backup.deepwatercreature.com";
    grafanaDataDir = lib.mkForce "/var/log/router-backup/grafana";
    prometheusStateDir = lib.mkForce "router-backup-prometheus";
    prometheusBindMountPath = lib.mkForce "/var/log/router-backup/prometheus";
  };

  # Intel I219 dual-port NIC via PCI passthrough.
  # Interface names are PCI-bus-derived (enp<bus>s<slot>) — set these to
  # the actual names observed after first boot on the target cluster node.
  services.router-networking = {
    wan.device = lib.mkForce "enp2s0";
    routedInterfaces.lan.device = lib.mkForce "enp3s0";
  };

  services.router-optimizations.interfaces = {
    wan.device = lib.mkForce "enp2s0";
    lan.device = lib.mkForce "enp3s0";
  };

  # Keep the backup router reachable on the out-of-band virtio management
  # network while sharing the same production LAN identity as the primary.
  services.router-networking.routedInterfaces.management.ipv4Address = lib.mkForce "192.168.100.99/24";

  services.router-firewall.extraInputRules = lib.mkForce ''
    iifname {"enp3s0"} tcp dport 5201 accept comment "iperf3 from LAN"
  '';

  # No separate logs disk on backup router — log locally.
  services.router-log-storage.enable = lib.mkForce false;
}
