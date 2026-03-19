{
  inputs,
  ...
}:
{
  # Declarative host configuration
  host.type = "lxc";
  host.networking.enableTailscale = false;  # LXC containers can't run Tailscale

  imports = [
    ../../../modules/nixos/common  # Common NixOS modules including ssh-keys-manager
    ../../../modules/nixos/attic-client.nix  # Attic binary cache client
    ../../../modules/nixos/nix-daemon-user-ssh.nix  # SSH socket for git+ssh flake inputs
    ./modules/configuration.nix
    ./modules/containers.nix
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

  # Enable nix-daemon to use user's SSH socket for git+ssh flake inputs
  myModules.nix-daemon-user-ssh.enable = true;

  # Use the stable per-host agenix identity instead of relying on SSH host keys.
  my.agenix.machineIdentity.enable = true;
  my.agenix.machineIdentity.legacyHostKeyFallback = false;
}
