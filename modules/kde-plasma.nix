{
  config,
  pkgs,
  ...
}:

{
  # KDE Plasma Home Manager configuration
  programs.plasma = {
    enable = true;

    # Hotkeys configuration
    hotkeys.commands = {
      "Launch-Vicinae" = {
        key = "Alt+Space";
        command = "${pkgs.vicinae}/bin/vicinae toggle";
      };
      "Launch-Vicinae-Meta" = {
        key = "Meta+Space";
        command = "${pkgs.vicinae}/bin/vicinae toggle";
      };
      "Launch-Krunner" = {
        key = "Alt+F2";
        command = "krunner";
      };
      "Show-Desktop-Grid" = {
        key = "Meta";
        command = "qdbus org.kde.kglobalshortcuts /component/kwin invokeShortcut \"ShowDesktopGrid\"";
      };
    };
  };

  # Enable Vicinae launcher
  programs.vicinae.enable = true;

  # KDE-specific applications
  home.packages = with pkgs; [
    kdePackages.krunner
    kdePackages.krohnkite
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
