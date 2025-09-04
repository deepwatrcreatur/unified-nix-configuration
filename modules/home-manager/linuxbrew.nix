{ config, lib, pkgs, ... }:

with lib;

let
  brewPrefix = "/home/linuxbrew/.linuxbrew";
  commonBrews = (import ../common-brew-packages.nix).brews;
in
{
  # Add Homebrew to PATH and environment
  home.sessionPath = [ "${brewPrefix}/bin" "${brewPrefix}/sbin" ];
  
  home.sessionVariables = {
    HOMEBREW_PREFIX = brewPrefix;
    HOMEBREW_CELLAR = "${brewPrefix}/Cellar";
    HOMEBREW_REPOSITORY = "${brewPrefix}/Homebrew";
  };

  # Shell integration
  programs.bash.initExtra = mkIf config.programs.bash.enable ''
    if [ -f "${brewPrefix}/bin/brew" ]; then
      eval "$(${brewPrefix}/bin/brew shellenv)"
    fi
  '';

  programs.fish.shellInit = mkIf config.programs.fish.enable ''
    if test -f "${brewPrefix}/bin/brew"
      eval (${brewPrefix}/bin/brew shellenv)
    end
  '';

  # Install script for common packages
  home.file.".local/bin/install-brew-packages" = {
    text = ''
      #!/bin/bash
      set -eu
      
      # Install Homebrew if not present
      if [ ! -f "${brewPrefix}/bin/brew" ]; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi

      # Set up environment
      export PATH="${brewPrefix}/bin:${brewPrefix}/sbin:$PATH"
      
      # Install common packages
      ${concatStringsSep "\n" (map (formula: ''
        if ! "${brewPrefix}/bin/brew" list "${formula}" &>/dev/null; then
          echo "Installing formula: ${formula}"
          "${brewPrefix}/bin/brew" install "${formula}"
        fi
      '') commonBrews)}
      
      echo "All common brew packages installed!"
    '';
    executable = true;
  };
}