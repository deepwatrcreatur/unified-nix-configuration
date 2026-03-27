# hosts/nixos-lxc/podman/stacks/plex-stack.nix
# Plex Media Server using container-stack module
{ ... }:

{
  services.containerStacks.plex = {
    network = "host";

    containers.plex = {
      image = "plexinc/pms-docker:latest";
      volumes = [
        "/var/lib/plex/config:/config"
        "/var/lib/plex/transcode:/transcode"
      ];
      environment = {
        TZ = "America/Toronto";
        PLEX_UID = "1000";
        PLEX_GID = "1000";
      };
    };

    directories = [
      { path = "/var/lib/plex"; mode = "0777"; }
      { path = "/var/lib/plex/config"; mode = "0777"; }
      { path = "/var/lib/plex/transcode"; mode = "0777"; }
    ];

    firewall = {
      allowedTCPPorts = [ 3005 8324 32400 32469 ];
      allowedUDPPorts = [ 1900 32410 32412 32413 32414 ];
    };
  };
}
