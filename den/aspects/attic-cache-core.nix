{ ... }:
let
  hostsData = import ../../lib/hosts.nix;
in
{ ... }:
{
  imports = [
    ../../hosts/nixos/default.nix
    ../../hosts/nixos-lxc/lxc-systemd-suppressions.nix
    ../../hosts/nixos-lxc/attic-cache/modules/configuration.nix
    ../../hosts/nixos-lxc/attic-cache/modules/packages.nix
    ../../hosts/nixos-lxc/attic-cache/modules/users.nix
    ../../hosts/nixos-lxc/attic-cache/modules/agenix.nix
    ../../modules/nixos/services/iperf3.nix
    ../../modules/nixos/attic-observatory.nix
  ];

  host.services.iperf3 = {
    enable = true;
    bindProbeAddress = hostsData.hosts.attic-cache.ip;
  };
}
