{
  config,
  lib,
  pkgs,
  cfg,
  ...}: let
    brewPrefix = if cfg.brewPrefix != "/home/linuxbrew/.linuxbrew" then cfg.brewPrefix else "/home/linuxbrew/.linuxbrew";
    commonBrews = (import ../common-brew-packages.nix).brews;
    brewCfg = config.programs.homebrew;

    # Build PATH with nix tools for brew operations
    nixToolsPath = lib.concatStringsSep ":" [
      "${pkgs.coreutils}/bin"
      "${pkgs.findutils}/bin"
      "${pkgs.git}/bin"
      "${pkgs.openssh}/bin"
      "${pkgs.curl}/bin"
      "${pkgs.gnugrep}/bin"
      "${pkgs.gnused}/bin"
      "${pkgs.gawk}/bin"
      "${pkgs.gnutar}/bin"
      "${pkgs.gzip}/bin"
      "${pkgs.which}/bin"
    ];
in
{
  # Add Homebrew module
  home.packages = with pkgs; [
    (import ../../common-brew-packages.nix)
  ];
}