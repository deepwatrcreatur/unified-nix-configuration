# hosts/nixos-lxc/ansible/default.nix
{
  imports = [
    ./modules/configuration.nix
    ./modules/packages.nix
    ./modules/users.nix
    ./modules/sops.nix
  ];
}
