{
  config,
  lib,
  pkgs,
  ...
}:

{
  # RustDesk Server configuration
  services.rustdesk-server = {
    enable = true;
    # Default ports:
    # - 21115: TCP (control)
    # - 21116: TCP (file transfer)
    # - 21117: TCP (audio)
    # - 21118: TCP (keyboard/mouse)
    # - 21119: TCP (clipboard)
    # - 5443: TCP (relay)
  };

  # Open necessary ports for RustDesk
  networking.firewall.allowedTCPPorts = [
    21115 # Control
    21116 # File transfer
    21117 # Audio
    21118 # Keyboard/mouse
    21119 # Clipboard
    5443  # Relay
  ];

  # Ensure hbbs (ID/Relay Server) service is running
  systemd.services.rustdesk-server.after = [ "network-online.target" ];
  systemd.services.rustdesk-server.wants = [ "network-online.target" ];
}
