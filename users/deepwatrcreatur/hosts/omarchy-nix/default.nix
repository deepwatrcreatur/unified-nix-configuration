
{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../default.nix
  ];

  home.username = "deepwatrcreatur";
  home.homeDirectory = "/home/deepwatrcreatur";

  # Omarchy-specific home configuration will be handled by the module
  # The omarchy-nix home manager module automatically configures:
  # - Hyprland window manager
  # - Terminal (kitty or similar)
  # - Editor configuration
  # - Application theming
  # - Wallpapers and color schemes

  home.packages = with pkgs; [
    firefox
  ];

  home.stateVersion = "24.11";
}
