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
      CreateDesktop = true;
    };
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      AppleShowScrollBars = "Always"; # Always show scroll bars ("Automatic" or "WhenScrolling")
      "com.apple.swipescrolldirection" = true;
    };
    screencapture = {
      location = "~/Pictures/Screenshots";
      disable-shadow = true;
      type = "png"; # Screenshot format: "png", "jpg", "tiff", etc.
    };
    screensaver = {
      # askForPassword = true; 
    };
    #loginwindow = {
    #  GuestEnabled = false; # Disable guest account
    #  SHOWFULLNAME = true; # Show full names instead of usernames at login
      # LoginwindowText = "Welcome to My Mac"; # Custom login screen message
    #};
  };
  
  # Activation script for unsupported settings
  system.activationScripts.postActivation.text = ''
    # Disable Fast User Switching menu item
    /usr/bin/defaults write /Library/Preferences/.GlobalPreferences.plist MultipleSessionEnabled -bool false
    
    # Disable screensaver password prompt
    #/usr/bin/defaults -currentHost write com.apple.screensaver askForPassword -bool false
    #/usr/bin/defaults -currentHost write com.apple.screensaver askForPasswordDelay -int 0

    # Configure menu bar clock
    /usr/bin/defaults write com.apple.menuextra.clock IsAnalog -bool false
    /usr/bin/defaults write com.apple.menuextra.clock Show24Hour -bool true
    /usr/bin/defaults write com.apple.menuextra.clock ShowDate -int 1
    /usr/bin/defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    /usr/bin/killall SystemUIServer
  '';
}
