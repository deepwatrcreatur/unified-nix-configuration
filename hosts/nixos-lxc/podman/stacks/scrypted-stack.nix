# hosts/nixos-lxc/podman/stacks/scrypted-stack.nix
# Scrypted NVR / HomeKit bridge running in a podman container (host networking)
{ config, lib, pkgs, ... }:

{
  services.containerStacks.scrypted = {
    # Host networking is recommended by Scrypted for HomeKit/mDNS
    network = "host";

    containers.scrypted = {
      image = "koush/scrypted:latest";
      volumes = [
        "/var/lib/scrypted:/server/volume"
      ];
      environment = {
        # Ensure Scrypted listens on all interfaces
        SCRYPTED_SECURE_PORT = "10443";
      };
    };

    # Persistent data directory for Scrypted configuration and recordings
    directories = [
      { path = "/var/lib/scrypted"; mode = "0770"; user = "root"; group = "root"; }
    ];

    # Expose Scrypted HTTPS port on the podman LXC host; Caddy on router will
    # terminate public TLS and reverse-proxy to this.
    firewall.allowedTCPPorts = [ 10443 ];
  };
}
