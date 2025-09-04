{ config, lib, pkgs, ... }:

with lib;

let
  brewPrefix = "/home/linuxbrew/.linuxbrew";
  commonBrews = (import ../common-brew-packages.nix).brews;
in
{
  # Add Homebrew environment variables (PATH handled in env.nix)
  
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

  programs.nushell.extraConfig = mkIf config.programs.nushell.enable ''
    # Add Homebrew to PATH if it exists
    if ("${brewPrefix}/bin/brew" | path exists) {
      $env.PATH = ($env.PATH | prepend "${brewPrefix}/bin" | prepend "${brewPrefix}/sbin")
      $env.HOMEBREW_PREFIX = "${brewPrefix}"
      $env.HOMEBREW_CELLAR = "${brewPrefix}/Cellar"
      $env.HOMEBREW_REPOSITORY = "${brewPrefix}/Homebrew"
    }
  '';

  # Install script for common packages
  home.file.".local/bin/install-brew-packages" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      set -eu
      
      # Install Homebrew if not present
      if [ ! -f "${brewPrefix}/bin/brew" ]; then
        echo "Installing Homebrew to ${brewPrefix}..."
        
        # Set up comprehensive PATH for homebrew installer on NixOS
        export PATH="${pkgs.coreutils}/bin:${pkgs.util-linux}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.git}/bin:${pkgs.curl}/bin:${pkgs.glibc.bin}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:${pkgs.which}/bin:${pkgs.ruby}/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:$PATH"
        
        # Run the installer with proper environment
        NONINTERACTIVE=1 ${pkgs.bash}/bin/bash -c "$(${pkgs.curl}/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi

      # Set up environment
      export PATH="${brewPrefix}/bin:${brewPrefix}/sbin:$PATH"
      export HOMEBREW_PREFIX="${brewPrefix}"
      export HOMEBREW_CELLAR="${brewPrefix}/Cellar"
      export HOMEBREW_REPOSITORY="${brewPrefix}/Homebrew"
      
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