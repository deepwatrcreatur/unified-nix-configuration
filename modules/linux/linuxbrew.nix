{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.homebrew;
in
{
  options.programs.homebrew = {
    enable = mkEnableOption "Homebrew package manager for Linux";

    brewPrefix = mkOption {
      type = types.str;
      default = "/home/linuxbrew/.linuxbrew";
      description = "Path where Homebrew is installed";
    };

    brews = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of Homebrew formulae to install";
    };

    casks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of Homebrew casks to install (if supported on Linux)";
    };

    taps = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of Homebrew taps to add";
    };

    onActivation = {
      cleanup = mkOption {
        type = types.enum [
          "none"
          "uninstall"
          "zap"
        ];
        default = "none";
        description = "Cleanup strategy for Homebrew packages";
      };

      autoUpdate = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to auto-update Homebrew on activation";
      };

      upgrade = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to upgrade Homebrew packages on activation";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      curl
      git
      gcc
    ];

    # Add Homebrew to PATH and set environment variables
    environment.variables = {
      HOMEBREW_PREFIX = cfg.brewPrefix;
      HOMEBREW_CELLAR = "${cfg.brewPrefix}/Cellar";
      HOMEBREW_REPOSITORY = "${cfg.brewPrefix}/Homebrew";
      MANPATH = "${cfg.brewPrefix}/share/man:";
      INFOPATH = "${cfg.brewPrefix}/share/info:";
    };

    environment.extraInit = ''
      if [ -f "${cfg.brewPrefix}/bin/brew" ]; then
        eval "$(${cfg.brewPrefix}/bin/brew shellenv)"
      fi
    '';

    # Add Homebrew bin to PATH
    environment.sessionVariables.PATH = [
      "${cfg.brewPrefix}/bin"
      "${cfg.brewPrefix}/sbin"
    ];

    
  };
}
