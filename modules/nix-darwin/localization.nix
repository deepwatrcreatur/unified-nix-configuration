{
  system.defaults.NSGlobalDomain = {
    # Time and Date
    AppleICUForce24HourTime = false;
    
    # Units
    AppleMeasurementUnits = "Centimeters";
    AppleMetricUnits      = 1;
    AppleTemperatureUnit  = "Celsius";
    
    # Keyboard settings
    AppleKeyboardUIMode = 3; # Full keyboard access for all controls
  };

  # Settings that need to be in Apple Global Domain
  system.defaults.CustomSystemPreferences."Apple Global Domain" = {
    # Sound settings
    "com.apple.sound.beep.flash" = false; # Disable visual bell
    
    # Trackpad settings
    "com.apple.trackpad.forceClick" = true; # Enable force click
  };
}
