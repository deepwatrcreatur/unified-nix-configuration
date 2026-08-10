# modules/home-manager/hunk.nix
# Dendritic Opt-in Home Manager Module for Hunk diff viewer (macOS & Linux)
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.programs.hunk-custom;
  hunkPkg = inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  imports = [
    inputs.hunk.homeManagerModules.default
  ];

  options.programs.hunk-custom = {
    enable = lib.mkEnableOption "Hunk review-first terminal diff viewer for macOS & Linux";
    enableGitIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Configure Git to use Hunk for diff/show/patch operations.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hunk = {
      enable = true;
      package = hunkPkg;
      enableGitIntegration = cfg.enableGitIntegration;
      settings = {
        mode = "split";
        line_numbers = true;
      };
    };

    home.shellAliases = {
      hd = "hunk diff";
      hdw = "hunk diff --watch";
      hs = "hunk show";
    };
  };
}
