# hosts/nixos-lxc/cache-build-server/default.nix
{
  inputs,
  ...
}:
{
  host.services.iperf3.enable = true;

  imports = [
    ../../../modules/nixos/services/iperf3.nix
    ../../../modules/nixos/attic-observatory.nix
    ../../../modules/nixos/common/nix-ci-netrc.nix
    ./modules/configuration.nix
    ./modules/build-server.nix
    ./modules/home-manager-users.nix
    ./modules/packages.nix
    ./modules/users.nix
    ./modules/agenix.nix
    # inputs.nix-attic-infra.nixosModules.attic-client  # Disabled - requires sops-nix
    inputs.agenix.nixosModules.default
  ];
}
