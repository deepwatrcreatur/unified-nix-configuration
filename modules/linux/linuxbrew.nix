{ config, lib, pkgs, ... }:

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
      default = [];
      description = "List of Homebrew formulae to install";
    };

    casks = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of Homebrew casks to install (if supported on Linux)";
    };

    taps = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of Homebrew taps to add";
    };

    onActivation = {
      cleanup = mkOption {
        type = types.enum [ "none" "uninstall" "zap" ];
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
    environment.sessionVariables.PATH = [ "${cfg.brewPrefix}/bin" "${cfg.brewPrefix}/sbin" ];

    # Install Homebrew and manage packages
    system.activationScripts.homebrew = lib.mkIf (cfg.brews != [] || cfg.casks != [] || cfg.taps != []) ''
      # Install Homebrew if not present
      if [ ! -f "${cfg.brewPrefix}/bin/brew" ]; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi

      # Set up environment for this script
      export PATH="${cfg.brewPrefix}/bin:${cfg.brewPrefix}/sbin:$PATH"
      export HOMEBREW_PREFIX="${cfg.brewPrefix}"
      export HOMEBREW_CELLAR="${cfg.brewPrefix}/Cellar"
      export HOMEBREW_REPOSITORY="${cfg.brewPrefix}/Homebrew"

      # Auto-update if requested
      ${optionalString cfg.onActivation.autoUpdate ''
        echo "Updating Homebrew..."
        "${cfg.brewPrefix}/bin/brew" update
      ''}

      # Add taps
      ${concatStringsSep "\n" (map (tap: ''
        echo "Adding tap: ${tap}"
        "${cfg.brewPrefix}/bin/brew" tap "${tap}" || true
      '') cfg.taps)}

      # Install formulae
      ${concatStringsSep "\n" (map (formula: ''
        if ! "${cfg.brewPrefix}/bin/brew" list "${formula}" &>/dev/null; then
          echo "Installing formula: ${formula}"
          "${cfg.brewPrefix}/bin/brew" install "${formula}"
        fi
      '') cfg.brews)}

      # Install casks (if any are specified)
      ${concatStringsSep "\n" (map (cask: ''
        if ! "${cfg.brewPrefix}/bin/brew" list --cask "${cask}" &>/dev/null; then
          echo "Installing cask: ${cask}"
          "${cfg.brewPrefix}/bin/brew" install --cask "${cask}" || echo "Cask ${cask} may not be supported on Linux"
        fi
      '') cfg.casks)}

      # Upgrade packages if requested
      ${optionalString cfg.onActivation.upgrade ''
        echo "Upgrading Homebrew packages..."
        "${cfg.brewPrefix}/bin/brew" upgrade
      ''}

      # Cleanup based on strategy
      ${optionalString (cfg.onActivation.cleanup != "none") ''
        echo "Cleaning up Homebrew..."
        "${cfg.brewPrefix}/bin/brew" cleanup
        ${optionalString (cfg.onActivation.cleanup == "zap") ''
          "${cfg.brewPrefix}/bin/brew" autoremove
        ''}
      ''}
    '';
  };
}