{ pkgs, lib, ... }:

{
  # Install Ghostty on Linux
  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.ghostty
  ];

  # Manage the Ghostty configuration file
  xdg.configFile."ghostty/config" = {
    source = ./config;
  };

  # Copy the Sugarplum theme to the themes folder
  xdg.configFile."ghostty/themes/Sugarplum" = {
    source = ./themes/Sugarplum;
  };

  # Ensure the themes folder exists
  home.activation = {
    createGhosttyThemesFolder = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $HOME/.config/ghostty/themes
    '';
  };
}
