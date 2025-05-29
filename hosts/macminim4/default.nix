{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/nix-darwin
    ./nix-store-uuid.nix
    ./just.nix
  ];

  nix.enable = false; # Required for Determinate Nix Installer

  programs.fish.enable = true;
    
  services.tailscale.enable = true;

  system.defaults = {
    dock = {
      orientation = "right"; # Dock position: "bottom", "left", or "right"
      autohide = true;
      minimize-to-application = false; # Minimize windows into their app icon
      # mineffect = "genie"; # Minimize effect: "genie", "scale", or "suck"
      show-recents = true;
      tilesize = 48;
      largesize = 64; # Size of magnified icons
      magnification = true; # Enable magnification when hovering over Dock icons
      wvous-tl-corner = 2; # Mission Control
      #wvous-br-corner = 5; # Screen Saver
    };
    menuExtras = {
      clock = {
        IsAnalog = false; # Use digital clock
        Show24Hour = false; # Use 24-hour clock
        ShowDate = true; # Show date in menu bar
        ShowDayOfWeek = true; # Show day of week
      };
    };
    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      ShowStatusBar = true; # Show status bar in Finder
      CreateDesktop = true;
      FXEnableExtensionChangeWarning = true; # Disable warning when changing file extensions
    };
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      NSNavPanelExpandedStateForSaveMode = true; # Expand save dialogs by default
      AppleShowScrollBars = "Always"; # Always show scroll bars ("Automatic" or "WhenScrolling")
      NSDocumentSaveNewDocumentsToCloud = false; # Save documents locally by default
    };
    screencapture = {
      location = "~/Pictures/Screenshots";
      disable-shadow = true;
      type = "png"; # Screenshot format: "png", "jpg", "tiff", etc.
    };
    screensaver = {
      askForPassword = false; # As requested previously
    };
    loginwindow = {
      GuestEnabled = false; # Disable guest account
      SHOWFULLNAME = true; # Show full names instead of usernames at login
      # LoginwindowText = "Welcome to My Mac"; # Custom login screen message
    };
    SoftwareUpdate = {
      AutomaticallyInstallMacOSUpdates = false; # Disable automatic macOS updates
      AutomaticCheckEnabled = true; # Check for updates automatically
      AutomaticDownload = false; # Don’t auto-download updates
    };
  };

  # Define the primary user for user-specific settings
  # required to enable some recently-added functionality
  system.primaryUser = "deepwatrcreatur";
  
  users.users.deepwatrcreatur = {
    name = "deepwatrcreatur";
    home = "/Users/deepwatrcreatur";
  };

  system.stateVersion = 4;
}
