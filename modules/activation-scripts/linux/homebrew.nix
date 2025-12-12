{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.activation-scripts.linux.homebrew;
  
  homebrewScript = pkgs.writeShellScript "homebrew-activation.sh" ''
    runuser -u ${config.users.users.deepwatrcreatur.name} -- /bin/bash -c "$(cat <<'EOF'
      export PATH="${pkgs.git}/bin:${pkgs.gcc}/bin:$PATH"
      # Install Homebrew if not present
      if [ ! -f "${cfg.brewPrefix}/bin/brew" ]; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(${pkgs.curl}/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi

      # Set up environment for this script
      export PATH="${cfg.brewPrefix}/bin:${cfg.brewPrefix}/sbin:$PATH"
      export HOMEBREW_PREFIX="${cfg.brewPrefix}"
      export HOMEBREW_CELLAR="${cfg.brewPrefix}/Cellar"
      export HOMEBREW_REPOSITORY="${cfg.brewPrefix}/Homebrew"

      # Auto-update if requested
      ${lib.optionalString cfg.onActivation.autoUpdate ''
        echo "Updating Homebrew..."
        "${cfg.brewPrefix}/bin/brew" update
      ''}

      # Add taps
      ${lib.concatStringsSep "\n" (
        lib.map (tap: ''
          echo "Adding tap: ${tap}"
          "${cfg.brewPrefix}/bin/brew" tap "${tap}" || true
        '') cfg.taps
      )}

      # Install formulae
      ${lib.concatStringsSep "\n" (
        lib.map (formula: ''
          if ! "${cfg.brewPrefix}/bin/brew" list "${formula}" &>/dev/null; then
            echo "Installing formula: ${formula}"
            "${cfg.brewPrefix}/bin/brew" install "${formula}"
          fi
        '') cfg.brews
      )}

      # Install casks (if any are specified)
      ${lib.concatStringsSep "\n" (
        lib.map (cask: ''
          if ! "${cfg.brewPrefix}/bin/brew" list --cask "${cask}" &>/dev/null; then
            echo "Installing cask: ${cask}"
            "${cfg.brewPrefix}/bin/brew" install --cask "${cask}" || echo "Cask ${cask} may not be supported on Linux"
          fi
        '') cfg.casks
      )}

      # Upgrade packages if requested
      ${lib.optionalString cfg.onActivation.upgrade ''
        echo "Upgrading Homebrew packages..."
        "${cfg.brewPrefix}/bin/brew" upgrade
      ''}

      # Cleanup based on strategy
      ${lib.optionalString (cfg.onActivation.cleanup != "none") ''
        echo "Cleaning up Homebrew..."
        "${cfg.brewPrefix}/bin/brew" cleanup
        ${lib.optionalString (cfg.onActivation.cleanup == "zap") ''
          "${cfg.brewPrefix}/bin/brew" autoremove
        ''}
      ''}
    EOF
    )"
  '';
in
{
  options.custom.activation-scripts.linux.homebrew = {
    enable = lib.mkEnableOption "Homebrew activation script for Linux";

    brewPrefix = lib.mkOption {
      type = lib.types.str;
      default = "/home/linuxbrew/.linuxbrew";
      description = "Path where Homebrew is installed";
    };

    brews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of Homebrew formulae to install";
    };

    casks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of Homebrew casks to install (if supported on Linux)";
    };

    taps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of Homebrew taps to add";
    };

    onActivation = {
      cleanup = lib.mkOption {
        type = lib.types.enum [
          "none"
          "uninstall"
          "zap"
        ];
        default = "none";
        description = "Cleanup strategy for Homebrew packages";
      };

      autoUpdate = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to auto-update Homebrew on activation";
      };

      upgrade = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to upgrade Homebrew packages on activation";
      };
    };
  };

  config = lib.mkIf (cfg.enable && (cfg.brews != [ ] || cfg.casks != [ ] || cfg.taps != [ ])) {
    system.activationScripts.homebrew.text = lib.mkAfter ''
      echo "Running Homebrew activation script..."
      ${homebrewScript}
    '';
  };
}