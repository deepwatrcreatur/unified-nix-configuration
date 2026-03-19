{
  inputs,
  ...
}:
{
  # Declarative host configuration
  host.type = "lxc";
  host.networking.enableTailscale = false; # LXC containers can't run Tailscale
  host.services.iperf3.enable = true;

  imports = [
    ../../../modules/nixos/common # Common NixOS modules including ssh-keys-manager
    ../../../modules/nixos/services/iperf3.nix
    ../../../modules/nixos/attic-client.nix # Attic binary cache client
    ../../../modules/nixos/nix-daemon-user-ssh.nix # SSH socket for git+ssh flake inputs
    ./modules/networking.nix
    ./modules/configuration.nix
    ./modules/homebridge.nix
    ./modules/home-manager-users.nix
    ./modules/users.nix
    inputs.agenix.nixosModules.default
    inputs.nix-semaphore.nixosModules.default
  ];

  # Semaphore Ansible UI
  services.semaphore = {
    enable = true;
    openFirewall = true;
    host = "http://homeserver:3000"; # Required for WebSocket connections
  };

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

  # Enable nix-daemon to use user's SSH socket for git+ssh flake inputs
  myModules.nix-daemon-user-ssh.enable = true;

  my.agenix.machineIdentity.enable = true;
}
