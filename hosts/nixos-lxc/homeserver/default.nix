{
  ...
}:
{
  # Declarative host configuration
  host.type = "lxc";
  host.services.iperf3.enable = true;

  imports = [
    ../../../modules/nixos/common  # Common NixOS modules including ssh-keys-manager
    ../../../modules/nixos/services/iperf3.nix
    ./modules/configuration.nix
    ./modules/homebridge.nix
    ./modules/home-manager-users.nix
    ./modules/users.nix
  ];

  # SSH keys manager - deploy authorized_keys from ssh-keys/ directory
  services.ssh-keys-manager.username = "deepwatrcreatur";
}
