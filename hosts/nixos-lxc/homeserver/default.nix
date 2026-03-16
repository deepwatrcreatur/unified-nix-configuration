{
  inputs,
  ...
}:
{
  # Declarative host configuration
  host.type = "lxc";
  host.services.iperf3.enable = true;

  imports = [
    ../../../modules/nixos/common  # Common NixOS modules including ssh-keys-manager
    ../../../modules/nixos/services/iperf3.nix
    ../../../modules/nixos/attic-client.nix  # Attic binary cache client
    ./modules/configuration.nix
    ./modules/homebridge.nix
    ./modules/home-manager-users.nix
    ./modules/users.nix
    inputs.agenix.nixosModules.default
  ];

  # SSH keys manager - deploy authorized_keys from ssh-keys/ directory
  services.ssh-keys-manager.username = "deepwatrcreatur";

  # Agenix secret for attic cache authentication
  age.secrets."attic-client-token" = {
    file = ../../../secrets-agenix/attic-client-token.age;
    path = "/run/secrets/attic-client-token";
    owner = "root";
    mode = "0400";
  };

  # Enable attic client for binary cache
  myModules.attic-client.enable = true;

  # Allow the Nix daemon to use the user's GPG SSH socket for git+ssh flake inputs
  systemd.services.nix-daemon.environment.SSH_AUTH_SOCK = "/run/user/1000/gnupg/S.gpg-agent.ssh";
}
