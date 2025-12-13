{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.activation-scripts.linux.homebrew;
  brewCfg = config.programs.homebrew;
  
  # Merge options from both sources - activation script options take precedence
  brews = if cfg.brews != [ ] then cfg.brews else brewCfg.brews;
  casks = if cfg.casks != [ ] then cfg.casks else brewCfg.casks;
  taps = if cfg.taps != [ ] then cfg.taps else brewCfg.taps;
  brewPrefix = if cfg.brewPrefix != "/home/linuxbrew/.linuxbrew" then cfg.brewPrefix else brewCfg.brewPrefix;
  
  homebrewScript = pkgs.writeShellScript "homebrew-activation.sh" ''
    set -e
    
    # Ensure essential tools are available
    export PATH="/usr/bin:${pkgs.git}/bin:${pkgs.openssh}/bin:${pkgs.curl}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.gawk}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:$PATH"
    
    runuser -u ${config.users.users.deepwatrcreatur.name} -- /bin/bash -c "$(cat <<'EOF'
      set -e
      
      # Ensure essential tools are available for brew operations
      export PATH="/usr/bin:${pkgs.git}/bin:${pkgs.openssh}/bin:${pkgs.curl}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.gawk}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:$PATH"
      
      # Install Homebrew if not present
      if [ ! -f "${brewPrefix}/bin/brew" ]; then
        echo "Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(${pkgs.curl}/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi

      # Set up environment for this script
      export PATH="${brewPrefix}/bin:${brewPrefix}/sbin:$PATH"
      export HOMEBREW_PREFIX="${brewPrefix}"
      export HOMEBREW_CELLAR="${brewPrefix}/Cellar"
      export HOMEBREW_REPOSITORY="${brewPrefix}/Homebrew"
      export HOMEBREW_NO_AUTO_UPDATE=1

      # Auto-update if requested
      ${lib.optionalString cfg.onActivation.autoUpdate ''
        echo "Updating Homebrew..."
        HOMEBREW_NO_AUTO_UPDATE=0 "${brewPrefix}/bin/brew" update
      ''}

      # Add taps
      ${lib.concatStringsSep "\n" (
        lib.map (tap: ''
          if ! "${brewPrefix}/bin/brew" tap | grep -q "^${tap}$"; then
            echo "Adding tap: ${tap}"
            "${brewPrefix}/bin/brew" tap "${tap}" || echo "Warning: Failed to tap ${tap}"
          fi
        '') taps
      )}

      # Install formulae
      ${lib.concatStringsSep "\n" (
        lib.map (formula: ''
          if ! "${brewPrefix}/bin/brew" list "${formula}" &>/dev/null; then
            echo "Installing formula: ${formula}"
            "${brewPrefix}/bin/brew" install "${formula}" || echo "Warning: Failed to install ${formula}"
          fi
        '') brews
      )}

      # Install casks (if any are specified)
      ${lib.concatStringsSep "\n" (
        lib.map (cask: ''
          if ! "${brewPrefix}/bin/brew" list --cask "${cask}" &>/dev/null; then
            echo "Installing cask: ${cask}"
            "${brewPrefix}/bin/brew" install --cask "${cask}" || echo "Warning: Cask ${cask} may not be supported on Linux"
          fi
        '') casks
      )}

      # Upgrade packages if requested
      ${lib.optionalString cfg.onActivation.upgrade ''
        echo "Upgrading Homebrew packages..."
        "${brewPrefix}/bin/brew" upgrade || true
      ''}

      # Cleanup based on strategy
      ${lib.optionalString (cfg.onActivation.cleanup != "none") ''
        echo "Cleaning up Homebrew..."
        "${brewPrefix}/bin/brew" cleanup || true
        ${lib.optionalString (cfg.onActivation.cleanup == "zap") ''
          "${brewPrefix}/bin/brew" autoremove || true
        ''}
      ''}
      
      echo "Homebrew activation complete."
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
      description = "List of Homebrew formulae to install (overrides programs.homebrew.brews if set)";
    };

    casks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of Homebrew casks to install (overrides programs.homebrew.casks if set)";
    };

    taps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of Homebrew taps to add (overrides programs.homebrew.taps if set)";
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

  config = lib.mkIf (cfg.enable && (brews != [ ] || casks != [ ] || taps != [ ])) {
    system.activationScripts.homebrew = {
      text = ''
        echo "Running Homebrew activation script..."
        ${homebrewScript}
      '';
      # Run after the symlinks are created
      deps = [ "brewSymlinks" ];
    };
  };
}
