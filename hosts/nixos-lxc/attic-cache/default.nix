# hosts/nixos-lxc/cache-build-server/default.nix
{
  inputs,
  ...
}:
{
  imports = [
    ../../../modules/nixos/attic-observatory.nix
    ./modules/configuration.nix
    ./modules/build-server.nix
    ./modules/home-manager-users.nix
    ./modules/packages.nix
    ./modules/users.nix
    ./modules/sops.nix
    inputs.nix-attic-infra.nixosModules.attic-client
    inputs.agenix.nixosModules.default
  ];
}
