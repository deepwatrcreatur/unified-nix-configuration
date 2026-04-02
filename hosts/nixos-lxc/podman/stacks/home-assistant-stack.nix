# hosts/nixos-lxc/podman/stacks/home-assistant-stack.nix
# Home Assistant Core running in a podman container
{ config, lib, pkgs, ... }:

{
  services.containerStacks.homeassistant = {
    # Host networking is required for many integrations (mDNS, SSDP, DHCP discovery)
    network = "host";

    containers.homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:stable";
      volumes = [
        "/var/lib/homeassistant:/config"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        TZ = "America/Toronto"; # Adjust to your timezone
      };
    };

    # Persistent data directory for Home Assistant configuration and database
    directories = [
      { path = "/var/lib/homeassistant"; mode = "0755"; user = "root"; group = "root"; }
    ];

    # Open the default Home Assistant port
    firewall.allowedTCPPorts = [ 8123 ];
  };
}
