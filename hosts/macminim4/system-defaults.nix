{ config, pkgs, ... }:

{

  system.defaults = {
    dock = {
      orientation = "right"; # Dock position: "bottom", "left", or "right"
      autohide = false;
      minimize-to-application = false; # Minimize windows into their app icon
      # mineffect = "genie"; # Minimize effect: "genie", "scale", or "suck"
      show-recents = true;
      tilesize = 48;
      largesize = 64; # Size of magnified icons
      magnification = true; # Enable magnification when hovering over Dock icons
      wvous-tl-corner = 2; # Mission Control
      #wvous-br-corner = 5; # Screen Saver
    };
    #menuExtras = {
    #  clock = {
    #    IsAnalog = false; # Use digital clock
    #    Show24Hour = false; # Use 24-hour clock
    #    ShowDate = true; # Show date in menu bar
    #    ShowDayOfWeek = true; # Show day of week
    #  };
    #};
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
      # askForPassword = true; 
    };
    LaunchServices = {
      LSQuarantine = false;
    };
    #loginwindow = {
    #  GuestEnabled = false; # Disable guest account
    #  SHOWFULLNAME = true; # Show full names instead of usernames at login
      # LoginwindowText = "Welcome to My Mac"; # Custom login screen message
    #};
  };

  # Activation script for unsupported settings
  system.activationScripts.postActivation.text = ''
    # Disable automatic software updates
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false

    # Configure menu bar clock
    /usr/bin/defaults write com.apple.menuextra.clock IsAnalog -bool false
    /usr/bin/defaults write com.apple.menuextra.clock Show24Hour -bool true
    /usr/bin/defaults write com.apple.menuextra.clock ShowDate -int 1
    /usr/bin/defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
    /usr/bin/killall SystemUIServer
  '';
}
