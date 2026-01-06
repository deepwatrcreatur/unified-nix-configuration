{ config, pkgs, ... }:

{
  # KDE Plasma Home Manager configuration
  programs.plasma = {
    enable = true;

    # Right-edge panel configuration - minimal, clean like COSMIC
    panels = [
      {
        location = "right";
        alignment = "center";
        height = 68;
        thickness = 60;
        visibilityMode = "AutoHide"; # Auto-hide, show on hover
        widgets = [
          {
            name = "org.kde.plasma.appmenu";
            config = {
              General.CompactMode = true;
            };
          }
          "org.kde.plasma.pager" # Workspace indicator with thumbnails
          "org.kde.plasma.systemtray"
          {
            name = "org.kde.plasma.digitalclock";
            config = {
              General.showDate = false;
              General.use24hFormat = true;
            };
          }
        ];
      }
    ];

    # Hotkeys configuration
    hotkeys.commands = {
      "Launch Krunner" = {
        key = "Meta+Space";
        command = "krunner";
      };
      "Show Desktop Grid" = {
        key = "Meta";
        command = "qdbus org.kde.kglobalshortcuts /component/kwin invokeShortcut 'ShowDesktopGrid'";
      };
    };

    # KDE appearance settings
    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
      splashScreen = "org.kde.breeze.desktop";
    };

    # Window decoration
    windows = {
      theme = "org.kde.breeze";
      decorationButtonsOnLeft = false; # macOS-style on right
    };

    # Tooltips visibility
    tooltips = {
      show = true;
    };
  };

  # KDE-specific applications and Thunderbird
  home.packages = with pkgs; [
    thunderbird
    kdePackages.krunner
  ];

  # Thunderbird integration for badge support
  # KDE's system tray will show Thunderbird badge counts
  programs.thunderbird = {
    enable = true;
  };
}
