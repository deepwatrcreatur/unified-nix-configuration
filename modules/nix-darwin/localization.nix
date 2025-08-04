{
  system.defaults.NSGlobalDomain = {
    # Time and Date
    AppleICUForce24HourTime = true;
    
    # Units
    AppleMeasurementUnits = "Centimeters";
    AppleMetricUnits      = 1;
    AppleTemperatureUnit  = "Celsius";
    
    # Language and Region
    AppleLanguages = [ "en-CA" ];  # Canadian English preference
    AppleLocale = "en_CA@currency=CAD";  # Canadian locale with CAD currency
    
    # Number and Currency Formatting
    AppleICUNumberSymbols = {
      "0"  = 46;   # Decimal separator (period)
      "1"  = 44;   # Thousands separator (comma)
      "10" = 46;  # Monetary decimal separator
      "17" = 36;  # Currency symbol ($) - CAD uses same symbol  };
    };
  };
}
