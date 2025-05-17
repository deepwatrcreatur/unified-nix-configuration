{ pkgs, ... }:

{
  # Ensure ghostty is installed
  home.packages = [
    pkgs.ghostty
  ];

  # Manage the ghostty configuration file
  xdg.configFile."ghostty/config" = {
    source = ./config;
  };
}

