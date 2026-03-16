# Declarative Podman containers for the podman LXC host
{ pkgs, lib, ... }:
{
  # Enable Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;  # Provides `docker` alias
    defaultNetwork.settings.dns_enabled = true;
    autoPrune.enable = true;
  };

  # Create persistent data directories
  systemd.tmpfiles.rules = [
    "d /var/lib/semaphore 0755 root root -"
    "d /var/lib/plex 0755 deepwatrcreatur deepwatrcreatur -"
    "d /var/lib/plex/config 0755 deepwatrcreatur deepwatrcreatur -"
    "d /var/lib/plex/transcode 0755 deepwatrcreatur deepwatrcreatur -"
  ];

  # Declarative OCI containers managed by systemd
  virtualisation.oci-containers = {
    backend = "podman";

    containers = {
      # Semaphore - Ansible Web UI
      semaphore = {
        image = "semaphoreui/semaphore:latest";
        ports = [ "3000:3000" ];
        volumes = [
          "/var/lib/semaphore:/etc/semaphore"
          # Mount SSH keys for Ansible to reach other hosts
          "/root/.ssh:/home/semaphore/.ssh:ro"
        ];
        environment = {
          SEMAPHORE_DB_DIALECT = "bolt";  # Simple file-based DB
          SEMAPHORE_ADMIN = "admin";
          # Set this after first run or use agenix for secrets
          # SEMAPHORE_ADMIN_PASSWORD = "changeme";
        };
        extraOptions = [
          "--name=semaphore"
        ];
      };

      # Plex Media Server
      plex = {
        image = "plexinc/pms-docker:latest";
        ports = [
          "32400:32400/tcp"
          "3005:3005/tcp"
          "8324:8324/tcp"
          "32469:32469/tcp"
          "1900:1900/udp"
          "32410:32410/udp"
          "32412:32412/udp"
          "32413:32413/udp"
          "32414:32414/udp"
        ];
        volumes = [
          "/var/lib/plex/config:/config"
          "/var/lib/plex/transcode:/transcode"
          # Mount your media library - adjust path as needed
          # "/mnt/media:/data:ro"
        ];
        environment = {
          TZ = "America/Toronto";
          PLEX_UID = "1000";
          PLEX_GID = "1000";
          # Claim token from https://plex.tv/claim (expires in 4 minutes)
          # PLEX_CLAIM = "claim-xxx";
        };
        extraOptions = [
          "--name=plex"
          "--network=host"  # Plex works best with host networking
        ];
      };
    };
  };

  # Open firewall ports
  networking.firewall = {
    allowedTCPPorts = [
      3000   # Semaphore
      32400  # Plex
      3005   # Plex
      8324   # Plex
      32469  # Plex
    ];
    allowedUDPPorts = [
      1900   # Plex DLNA
      32410  # Plex GDM
      32412  # Plex GDM
      32413  # Plex GDM
      32414  # Plex GDM
    ];
  };
}
