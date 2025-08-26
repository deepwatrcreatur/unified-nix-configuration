{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../default.nix  
  ];

  home.username = "deepwatrcreatur";
  home.homeDirectory = "/home/deepwatrcreatur";

  # Enable Hyprland through Home Manager for user-specific configuration
  wayland.windowManager.hyprland = {
    enable = true;
    # You can add custom Hyprland configuration here
    settings = {
      # Example custom keybindings (optional)
      "$mod" = "SUPER";
      bind = [
        # custom keybindings here
        # "$mod, F, exec, firefox"
        # "$mod, T, exec, kitty"
      ];
    };
  };

  # Enable required terminal for Hyprland default config
  programs.kitty.enable = true;
  
  home.packages = with pkgs; [
    firefox
  ];

  home.stateVersion = "25.05";
}