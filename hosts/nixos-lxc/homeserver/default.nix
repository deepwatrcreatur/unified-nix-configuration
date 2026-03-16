{
  ...
}:
{
  host.services.iperf3.enable = true;

  imports = [
    ../../../modules/nixos/services/iperf3.nix
    ./modules/configuration.nix
    ./modules/homebridge.nix
    ./modules/home-manager-users.nix
    ./modules/users.nix
  ];
}
