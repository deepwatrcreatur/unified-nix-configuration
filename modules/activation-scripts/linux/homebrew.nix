{
  config,
  lib,
  pkgs,
  cfg,
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
      }
      }
