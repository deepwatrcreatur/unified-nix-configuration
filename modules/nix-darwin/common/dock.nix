{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.home-manager.users.${config.system.primaryUser};
  hasZenBrowser = user ? programs.zen-browser.package;
  hasWezterm = config.programs.wezterm.enable or false;
in
{
  system.defaults.dock = {
    minimize-to-application = false;
    orientation = "left";
    autohide = true;
    showhidden = true; # Translucent.
    mouse-over-hilite-stack = true;
    show-recents = true;
    mru-spaces = false;
    tilesize = 48;
    largesize = 64;
    magnification = true;
    enable-spring-load-actions-on-all-items = true;
    persistent-apps =
      lib.optionals hasZenBrowser [
        { app = "${user.programs.zen-browser.package}/Applications/Zen Browser.app"; }
      ]
      ++ lib.optionals hasWezterm [
        { app = "${config.programs.wezterm.package}/Applications/WezTerm.app"; }
      ]
      ++ [
        { app = "/Applications/Ghostty.app"; }
      ];
  };

  system.defaults.CustomSystemPreferences."com.apple.dock" = {
    autohide-time-modifier = 0.0;
    autohide-delay = 0.0;
    expose-animation-duration = 0.0;
    springboard-show-duration = 0.0;
    springboard-hide-duration = 0.0;
    springboard-page-duration = 0.0;
    # hot corners.
    wvous-tr-corner = 0;
    wvous-br-corner = 0;
    # Top-left: ctrl to disable screensaver
    "wvous-tl-corner" = 6;
    "wvous-tl-modifier" = 262144;
    # Bottom-left: ctrl for launchpad (app chooser)
    "wvous-bl-corner" = 11;
    "wvous-bl-modifier" = 262144;
    launchanim = 0;
  };
}
