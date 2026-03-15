{ config, lib, pkgs, ... }:

{
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      AppleShowScrollBars = "Always";
      "com.apple.swipescrolldirection" = true;
    };
    screencapture = {
      location = "~/Pictures/Screenshots";
      disable-shadow = true;
      type = "png";
    };
  };

  # Activation script for unsupported settings
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # Disable Fast User Switching menu item
    /usr/bin/defaults write /Library/Preferences/.GlobalPreferences.plist MultipleSessionEnabled -bool false

    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    /usr/bin/killall SystemUIServer
  '';
}
