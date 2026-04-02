{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  plasmaManagerModule =
    if inputs.plasma-manager ? homeManagerModules
      && inputs.plasma-manager.homeManagerModules ? plasma-manager
    then
      inputs.plasma-manager.homeManagerModules.plasma-manager
    else if inputs.plasma-manager ? homeModules && inputs.plasma-manager.homeModules ? plasma-manager then
      inputs.plasma-manager.homeModules.plasma-manager
    else
      throw "plasma-session-base: plasma-manager flake no longer exposes a plasma-manager home module";

  plasmaBasePackages = with pkgs; [
    kdePackages.plasma-desktop
    kdePackages.systemsettings
    kdePackages.plasma-systemmonitor
    kdePackages.kate
    kdePackages.dolphin
    kdePackages.konsole
    dconf-editor
  ];

  plasmaFonts = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    fira-code
    fira-code-symbols
  ];
in
{
  imports = [ ./plasma-kwallet-support.nix ];

  home-manager.sharedModules = [
    plasmaManagerModule
    ../../kde-plasma.nix
  ];

  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;

  services.displayManager = {
    defaultSession = lib.mkDefault "plasma";
    autoLogin = {
      enable = lib.mkDefault true;
      user = lib.mkDefault "deepwatrcreatur";
    };
  };

  programs.dconf.enable = true;

  environment.systemPackages = plasmaBasePackages;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
  };

  fonts = {
    packages = plasmaFonts;

    fontconfig.defaultFonts = {
      monospace = [ "Fira Code" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
