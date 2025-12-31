{ config, pkgs, ... }:

{
  # GNOME Clock/Date Configuration
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      clock-show-date = true;  # This shows the date in the top bar
      clock-show-weekday = true;  # This shows the day of the week
    };
    
    "org/gnome/desktop/wm/preferences" = {
      # Additional clock formatting options
      clock-modifiers = "<Super>Period";
    };
  };

  # Alternative: More detailed clock format
  dconf.settings."org/gnome/shell" = {
    # Custom clock format - shows day, date, and time
    # Examples:
    # "%a %b %e, %I:%M %p" = "Mon Dec 30, 2:25 PM"
    # "%A, %B %e, %Y %I:%M %p" = "Monday, December 30, 2025 2:25 PM"
    # "%a %b %e %I:%M %p" = "Mon Dec 30 2:25 PM"
    clock-format = "%a %b %e, %I:%M %p";
  };
}