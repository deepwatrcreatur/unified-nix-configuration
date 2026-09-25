{ ... }:
let
  hostsData = import ../../lib/hosts.nix;
in
{ ... }:
{
  imports = [
    ../../hosts/nixos/default.nix
    ../../hosts/nixos-lxc/attic-cache/modules/configuration.nix
    ../../hosts/nixos-lxc/attic-cache/modules/packages.nix
    ../../hosts/nixos-lxc/attic-cache/modules/users.nix
    ../../hosts/nixos-lxc/attic-cache/modules/agenix.nix
    ../../modules/nixos/services/iperf3.nix
    ../../modules/nixos/attic-observatory.nix
  ];

  myModules.caches.isCacheServer = true;

  # Ensure atticd binary cache port (5001) is automatically opened on any host with this aspect
  networking.firewall.allowedTCPPorts = [ 5001 ];

  host.services.iperf3 = {
    enable = true;
    bindProbeAddress = hostsData.hosts.emerald.ip or hostsData.hosts.attic-cache.ip;
  };
}
