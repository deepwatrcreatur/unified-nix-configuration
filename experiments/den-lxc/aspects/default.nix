{ lib }:
{
  nixos-base = context: import ./nixos-base.nix context;
  lxc-core = context: import ./lxc-core.nix context;
  attic-client = context: import ./attic-client.nix context;
  nix-daemon-user-ssh = context: import ./nix-daemon-user-ssh.nix context;
  home-manager-users = context: import ./home-manager-users.nix context;
  homeserver-networking = context: import ./homeserver-networking.nix context;
  homeserver-iperf3 = context: import ./homeserver-iperf3.nix context;
  homeserver-homebridge = context: import ./homeserver-homebridge.nix context;
  homeserver-semaphore = context: import ./homeserver-semaphore.nix context;
  attic-cache-core = context: import ./attic-cache-core.nix context;
  attic-cache-build-server = context: import ./attic-cache-build-server.nix context;
  attic-cache-home-manager = context: import ./attic-cache-home-manager.nix context;
  rustdesk-server = context: import ./rustdesk-server.nix context;
  podman-containers = context: import ./podman-containers.nix context;
  podman-lxc-suppressions = context: import ./podman-lxc-suppressions.nix context;
}
