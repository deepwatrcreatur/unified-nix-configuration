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
    ./modules/agenix.nix
    # inputs.nix-attic-infra.nixosModules.attic-client  # Disabled - requires sops-nix
    inputs.agenix.nixosModules.default
  ];
}
