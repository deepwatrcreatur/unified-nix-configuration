# modules/home-manager/common/cmux-tui.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.cmux-tui;
  cmuxTuiPackage = pkgs.cmux-tui or (pkgs.callPackage ../../../pkgs/cmux-tui.nix { });
in
{
  options.programs.cmux-tui = {
    enable = lib.mkEnableOption "cmux-tui - terminal multiplexer for AI coding agents backed by libghostty-vt";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cmuxTuiPackage ];
  };
}
