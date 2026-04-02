{ ... }:
{ ... }:
{
  imports = [
    ../../modules/nixos/container-stack.nix
    ../../hosts/nixos-lxc/podman/stacks/plex-stack.nix
    ../../hosts/nixos-lxc/podman/stacks/nightscout-stack.nix
    ../../hosts/nixos-lxc/podman/stacks/paperless-stack.nix
    ../../hosts/nixos-lxc/podman/stacks/librelinkup-stack.nix
    ../../hosts/nixos-lxc/podman/stacks/scrypted-stack.nix
    ../../hosts/nixos-lxc/podman/stacks/home-assistant-stack.nix
  ];

  # Enable Podman with settings
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune.enable = true;
  };

  # Declarative OCI containers managed by systemd
  virtualisation.oci-containers = {
    backend = "podman";
  };

  # Create persistent data directories
  systemd.tmpfiles.rules = [
    "d /var/lib/plex 0777 root root -"
    "d /var/lib/plex/config 0777 root root -"
    "d /var/lib/plex/transcode 0777 root root -"
  ];

  # Open firewall ports
  networking.firewall = {
    allowedTCPPorts = [
      11337 # Nightscout
      32400 # Plex
      3005 # Plex
      8324 # Plex
      32469 # Plex
      8123 # Home Assistant
    ];
    allowedUDPPorts = [
      1900 # Plex DLNA
      32410 # Plex GDM
      32412 # Plex GDM
      32413 # Plex GDM
      32414 # Plex GDM
    ];
  };
}
