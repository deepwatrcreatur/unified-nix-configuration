{
  config,
  ...
}:
let
  topology = config.router.topology;
in
{
  imports = [
    ./service-capability.nix
  ];

  networking.hostName = "router";
  networking.domain = topology.domain;
}
