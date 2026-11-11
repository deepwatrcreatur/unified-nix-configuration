{
  config,
  pkgs,
  ...
}:

{
  # KDE Plasma Home Manager configuration
  programs.plasma = {
    enable = true;

    configFile."kwinrc"."Plugins"."konveyor_effectEnabled" = true;
    configFile."kwinrc"."Desktops"."Rows" = 1;

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

  # Enable Vicinae launcher. The hotkeys above run `vicinae toggle`, which
  # needs the server running, so start it with the graphical session.
  programs.vicinae = {
    enable = true;
    systemd.enable = true;
  };

  # KDE-specific applications
  home.packages = with pkgs; [
    kdePackages.krunner
    konveyor
    birdtray # System tray notification for Thunderbird
  ];

  # Declarative Konveyor configuration (dynamic workspaces in 1 horizontal row)
  xdg.configFile."konveyor/config.kdl".source = ./konveyor/config.kdl;

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
