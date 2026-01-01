{
  config,
  lib,
  pkgs,
  ...
}:

{
  # RustDesk Server - manually configured systemd services
  # hbbs: ID/Signal server (listens on port 21115)
  # hbbr: Relay server (listens on port 5443)

  # Create rustdesk user for service
  users.users.rustdesk = {
    isSystemUser = true;
    group = "rustdesk";
    home = "/var/lib/rustdesk";
    createHome = true;
    homeMode = "0700";
  };
  users.groups.rustdesk = {};

  # RustDesk ID/Signal Server (hbbs)
  systemd.services.hbbs = {
    description = "RustDesk ID/Signal Server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "rustdesk";
      Group = "rustdesk";
      StateDirectory = "rustdesk";
      WorkingDirectory = "/var/lib/rustdesk";
      ExecStart = "${pkgs.rustdesk-server}/bin/hbbs -r 127.0.0.1:21116";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # RustDesk Relay Server (hbbr)
  systemd.services.hbbr = {
    description = "RustDesk Relay Server";
    after = [ "network-online.target" "hbbs.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "rustdesk";
      Group = "rustdesk";
      StateDirectory = "rustdesk";
      WorkingDirectory = "/var/lib/rustdesk";
      ExecStart = "${pkgs.rustdesk-server}/bin/hbbr";
      Restart = "on-failure";
      RestartSec = "5s";
      # Increase bandwidth limits for gigabit networks
      Environment = [
        "LIMIT_SPEED=1000Mb/s"
        "TOTAL_BANDWIDTH=10000Mb/s"
        "SINGLE_BANDWIDTH=1000Mb/s"
      ];
    };
  };

  # Open necessary ports for RustDesk
  networking.firewall.allowedTCPPorts = [
    21115 # Control/Signal
    21116 # File transfer
    21117 # Audio
    21118 # Keyboard/mouse
    21119 # Clipboard
    5443 # Relay
  ];
}
