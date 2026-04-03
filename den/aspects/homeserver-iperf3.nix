{ ... }:
let
  hostsData = import ../../lib/hosts.nix;
in
{ ... }:
{
  imports = [
    ../../modules/nixos/services/iperf3.nix
  ];

  host.services.iperf3 = {
    enable = true;
    bindProbeAddress = hostsData.hosts.homeserver.ip;
  };
}
