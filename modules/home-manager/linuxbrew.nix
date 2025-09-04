{ config, lib, pkgs, ... }:

with lib;

let
  brewPrefix = "$HOME/.linuxbrew";
  commonBrews = (import ../common-brew-packages.nix).brews;
in
{
  # Add Homebrew to PATH and environment
  home.sessionPath = [ "$HOME/.linuxbrew/bin" "$HOME/.linuxbrew/sbin" ];
  
  home.sessionVariables = {
    HOMEBREW_PREFIX = "$HOME/.linuxbrew";
    HOMEBREW_CELLAR = "$HOME/.linuxbrew/Cellar";
    HOMEBREW_REPOSITORY = "$HOME/.linuxbrew/Homebrew";
  };

  # Shell integration
  programs.bash.initExtra = mkIf config.programs.bash.enable ''
    if [ -f "$HOME/.linuxbrew/bin/brew" ]; then
      eval "$($HOME/.linuxbrew/bin/brew shellenv)"
    fi
  '';

  programs.fish.shellInit = mkIf config.programs.fish.enable ''
    if test -f "$HOME/.linuxbrew/bin/brew"
      eval ($HOME/.linuxbrew/bin/brew shellenv)
    end
  '';

  # Install script for common packages
  home.file.".local/bin/install-brew-packages" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      set -eu
      
      # Install Homebrew if not present
      if [ ! -f "$HOME/.linuxbrew/bin/brew" ]; then
        echo "Installing Homebrew to $HOME/.linuxbrew..."
        export HOMEBREW_PREFIX="$HOME/.linuxbrew"
        ${pkgs.bash}/bin/bash -c "$(${pkgs.curl}/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi

      # Set up environment
      export PATH="$HOME/.linuxbrew/bin:$HOME/.linuxbrew/sbin:$PATH"
      export HOMEBREW_PREFIX="$HOME/.linuxbrew"
      export HOMEBREW_CELLAR="$HOME/.linuxbrew/Cellar"
      export HOMEBREW_REPOSITORY="$HOME/.linuxbrew/Homebrew"
      
      # Install common packages
      ${concatStringsSep "\n" (map (formula: ''
        if ! "$HOME/.linuxbrew/bin/brew" list "${formula}" &>/dev/null; then
          echo "Installing formula: ${formula}"
          "$HOME/.linuxbrew/bin/brew" install "${formula}"
        fi
      '') commonBrews)}
      
      echo "All common brew packages installed!"
    '';
    executable = true;
  };
}