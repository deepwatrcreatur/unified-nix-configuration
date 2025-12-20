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
  
  homebrewScript = pkgs.writeShellScript "homebrew-activation.sh" ''
    set -e
    
    # Ensure essential tools are available - export for child processes
    export NIX_TOOLS_PATH="${nixToolsPath}"
    export PATH="/usr/bin:$NIX_TOOLS_PATH:$PATH"
    
    runuser -u ${config.users.users.deepwatrcreatur.name} -- /bin/bash -c '
      set -e
      
      # Set comprehensive environment variables matching working CLI setup
      export HOME="/home/${config.users.users.deepwatrcreatur.name}"
      export PATH="${brewPrefix}/bin:${brewPrefix}/sbin:/usr/local/bin:/usr/bin:$NIX_TOOLS_PATH:$PATH"
      export SHELL="/bin/bash"
      
      # Install Homebrew if not present
      if [ ! -f "${brewPrefix}/bin/brew" ]; then
        echo "Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi

# Install system coreutils system-wide for Ruby compatibility
      echo "Installing system coreutils for Ruby compatibility..."
      # Install coreutils to make commands system-wide available
      ${pkgs.coreutils}/bin/nice --version >/dev/null && echo "Coreutils already installed" || {
        echo "Installing coreutils system-wide..."
        ${pkgs.coreutils}/bin/nice --version >/dev/null
      }
      
      # Create symlinks in all locations Ruby might search
      mkdir -p /usr/local/bin /usr/bin
      ln -sf ${pkgs.coreutils}/bin/nice /usr/local/bin/nice
      ln -sf ${pkgs.coreutils}/bin/nice /usr/bin/nice
      ln -sf ${pkgs.coreutils}/bin/nohup /usr/local/bin/nohup
      ln -sf ${pkgs.coreutils}/bin/timeout /usr/local/bin/timeout
      ln -sf ${pkgs.coreutils}/bin/timeout /usr/bin/timeout
      
      # Verify symlinks were created
      echo "Coreutils symlinks created: $(ls /usr/local/bin/nice /usr/bin/nice 2>/dev/null || echo "FAILED")"
      
      # Give system time to recognize coreutils
      sleep 2
      
      # Set up environment that matches working CLI setup
      export PATH="${brewPrefix}/bin:${brewPrefix}/sbin:$NIX_TOOLS_PATH:$PATH"
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
            PATH="${brewPrefix}/bin:${brewPrefix}/sbin:/usr/local/bin:$NIX_TOOLS_PATH:$PATH" "${brewPrefix}/bin/brew" tap "${tap}" || echo "Warning: Failed to tap ${tap}"
          fi
        '') taps
      )}

      # Helper function to create gcc symlinks if needed
      create_gcc_symlinks() {
        if [ ! -e "${brewPrefix}/bin/gcc" ]; then
          GCC_BIN=$(ls "${brewPrefix}/bin/gcc-"* 2>/dev/null | grep -E "gcc-[0-9]+$" | head -1)
          if [ -n "$GCC_BIN" ]; then
            GCC_VERSION=$(basename "$GCC_BIN" | sed "s/gcc-//")
            echo "Creating gcc symlinks to gcc-$GCC_VERSION..."
            ln -sf "${brewPrefix}/bin/gcc-$GCC_VERSION" "${brewPrefix}/bin/gcc"
            ln -sf "${brewPrefix}/bin/g++-$GCC_VERSION" "${brewPrefix}/bin/g++" 2>/dev/null || true
            ln -sf "${brewPrefix}/bin/cpp-$GCC_VERSION" "${brewPrefix}/bin/cpp" 2>/dev/null || true
          fi
        fi
      }

# Install formulae
      ${lib.concatStringsSep "\n" (
        lib.map (formula: ''
          if ! "${brewPrefix}/bin/brew" list "${formula}" &>/dev/null; then
            echo "Installing formula: ${formula}"
            # Skip bd (known Ruby issue during activation - install manually)
            if [[ "${formula}" == "bd" ]]; then
              echo "Skipping bd (Ruby nice issue during activation - install manually with: brew install bd)"
            else
              "${brewPrefix}/bin/brew" install "${formula}" || echo "Warning: Failed to install ${formula}"
            fi
          # Create gcc symlinks after gcc is installed (for subsequent source builds)
          ${lib.optionalString (formula == "gcc") "create_gcc_symlinks"}
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
      
# Install user-level packages that failed during activation
      echo "Installing user-level packages (post-activation)..."
      # Simple approach to avoid Nix syntax issues
      if ! "${brewPrefix}/bin/brew" list "ccat" &>/dev/null; then
        echo "User-level install: ccat"
        /run/wrappers/bin/su - ${config.users.users.deepwatrcreatur.name} -c "PATH=${brewPrefix}/bin:${brewPrefix}/sbin:\$PATH HOMEBREW_PREFIX=${brewPrefix} HOMEBREW_CELLAR=${brewPrefix}/Cellar HOMEBREW_REPOSITORY=${brewPrefix}/Homebrew ${brewPrefix}/bin/brew install ccat" || echo "Warning: User install of ccat failed"
      fi
      if ! "${brewPrefix}/bin/brew" list "ccat" &>/dev/null; then
        echo "User-level install: ccat"
        su - ${config.users.users.deepwatrcreatur.name} -c "PATH=${brewPrefix}/bin:${brewPrefix}/sbin:\$PATH HOMEBREW_PREFIX=${brewPrefix} HOMEBREW_CELLAR=${brewPrefix}/Cellar HOMEBREW_REPOSITORY=${brewPrefix}/Homebrew ${brewPrefix}/bin/brew install ccat" || echo "Warning: User install of ccat failed"
      fi
      if ! "${brewPrefix}/bin/brew" list "doggo" &>/dev/null; then
        echo "User-level install: doggo"
        su - ${config.users.users.deepwatrcreatur.name} -c "PATH=${brewPrefix}/bin:${brewPrefix}/sbin:\$PATH HOMEBREW_PREFIX=${brewPrefix} HOMEBREW_CELLAR=${brewPrefix}/Cellar HOMEBREW_REPOSITORY=${brewPrefix}/Homebrew ${brewPrefix}/bin/brew install doggo" || echo "Warning: User install of doggo failed"
      fi
      if ! "${brewPrefix}/bin/brew" list "silicon" &>/dev/null; then
        echo "User-level install: silicon"
        su - ${config.users.users.deepwatrcreatur.name} -c "PATH=${brewPrefix}/bin:${brewPrefix}/sbin:\$PATH HOMEBREW_PREFIX=${brewPrefix} HOMEBREW_CELLAR=${brewPrefix}/Cellar HOMEBREW_REPOSITORY=${brewPrefix}/Homebrew ${brewPrefix}/bin/brew install silicon" || echo "Warning: User install of silicon failed"
      fi
    '
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
