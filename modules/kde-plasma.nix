{ config, pkgs, ... }:

{
  # KDE Plasma Home Manager configuration
  programs.plasma = {
    enable = true;

    # Hotkeys configuration
    hotkeys.commands = {
      "Launch-Krunner" = {
        key = "Meta+Space";
        command = "krunner";
      };
      "Show-Desktop-Grid" = {
        key = "Meta";
        command = "qdbus org.kde.kglobalshortcuts /component/kwin invokeShortcut \"ShowDesktopGrid\"";
      };
    };
  };

  # KDE-specific applications
  home.packages = with pkgs; [
    kdePackages.krunner
    birdtray # System tray notification for Thunderbird
  ];

  # Autostart birdtray for Thunderbird notifications
  systemd.user.services.birdtray = {
    Unit = {
      Description = "Birdtray - Thunderbird system tray notification";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.birdtray}/bin/birdtray";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
