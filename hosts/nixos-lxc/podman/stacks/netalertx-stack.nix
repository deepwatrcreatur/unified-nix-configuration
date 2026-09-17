# hosts/nixos-lxc/podman/stacks/netalertx-stack.nix
# NetAlertX network scanner and device tracker using container-stack module
# Configured for low-noise evaluation (no spam notifications, initial server subnet only)
{ config, lib, pkgs, ... }:

{
  services.containerStacks.netalertx = {
    # Host networking is required for layer-2 ARP discovery
    network = "host";

    containers = {
      netalertx = {
        image = "ghcr.io/jokob-sk/netalertx:latest";
        volumes = [
          "/var/lib/netalertx/config:/app/config"
          "/var/lib/netalertx/db:/app/db"
          "/var/lib/netalertx/log:/app/front/log"
        ];
        environment = {
          PORT = "20211";
          TZ = "America/New_York";
          # Scan only server subnet initially to prevent new-device alert floods:
          SCAN_SUBNETS = "10.10.11.0/24";
          REPORT_NEW_DEVICES = "false";
          SCAN_TYPE = "arp-scan";
        };
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
        ];
      };
    };

    # Persistent data directories for NetAlertX configuration, database, and logs
    directories = [
      { path = "/var/lib/netalertx/config"; mode = "0755"; }
      { path = "/var/lib/netalertx/db"; mode = "0755"; }
      { path = "/var/lib/netalertx/log"; mode = "0755"; }
    ];

    firewall.allowedTCPPorts = [ 20211 ];
  };
}
