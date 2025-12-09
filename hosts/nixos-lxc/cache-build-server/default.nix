# hosts/nixos-lxc/cache-build-server/default.nix
{
  imports = [
    ./modules/configuration.nix
    ./modules/build-server.nix
    ./modules/home-manager-users.nix
    ./modules/packages.nix
    ./modules/users.nix
    ./modules/sops.nix
  ];
}
