{ pkgs, ... }:

{
  # the darwin nix package is marked as broken
  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.ghostty 
  ];

  # Manage the ghostty configuration file
  xdg.configFile."ghostty/config" = {
    source = ./config;
  };
}

