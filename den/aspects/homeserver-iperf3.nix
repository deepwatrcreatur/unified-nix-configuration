{ ... }:
{ ... }:
{
  imports = [
    ../../modules/nixos/services/iperf3.nix
  ];

  host.services.iperf3.enable = true;
}
