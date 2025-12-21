{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  brewPrefix = "/home/linuxbrew/.linuxbrew";
  commonPackages = import ../common-brew-packages.nix;
  commonBrews = commonPackages.brews;
  commonTaps = commonPackages.taps;

  # Script to install homebrew and packages (used by activation and available as command)
  installBrewScript = pkgs.writeShellScript "install-brew-packages" ''
    # Don't use set -e; we want to continue even if some packages fail
    set -u

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

    # Add taps (continue on failure)
    ${concatStringsSep "\n" (
      map (tap: ''
        if ! "${brewPrefix}/bin/brew" tap | ${pkgs.gnugrep}/bin/grep -q "^${tap}$"; then
          echo "Adding tap: ${tap}"
          "${brewPrefix}/bin/brew" tap "${tap}" || echo "Warning: Failed to add tap ${tap}"
        fi
      '') commonTaps
    )}

    # Install and link common packages (continue on failure)
    ${concatStringsSep "\n" (
      map (formula: ''
        if ! "${brewPrefix}/bin/brew" list "${formula}" &>/dev/null; then
          echo "Installing formula: ${formula}"
          "${brewPrefix}/bin/brew" install "${formula}" || echo "Warning: Failed to install ${formula}"
        fi
        # Ensure package is linked (overwrite stale links)
        "${brewPrefix}/bin/brew" link --overwrite "${formula}" 2>/dev/null || true
      '') commonBrews
    )}

    echo "Homebrew setup complete!"
    echo "Run 'brew upgrade' to update outdated packages"
  '';
in
{
  # Add Homebrew environment variables
  home.sessionVariables = {
    HOMEBREW_PREFIX = brewPrefix;
    HOMEBREW_CELLAR = "${brewPrefix}/Cellar";
    HOMEBREW_REPOSITORY = "${brewPrefix}/Homebrew";
  };

  # Add ~/.local/bin to PATH
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Shell integration
  programs.bash.initExtra = mkIf config.programs.bash.enable ''
    if [ -f "${brewPrefix}/bin/brew" ]; then
      export PATH="${brewPrefix}/bin:${brewPrefix}/sbin:$PATH"
    fi'';

  programs.fish.shellInit = mkIf config.programs.fish.enable ''
    if test -f "${brewPrefix}/bin/brew"
      fish_add_path --prepend "${brewPrefix}/bin" "${brewPrefix}/sbin"
    end'';

  programs.nushell.extraConfig = mkIf config.programs.nushell.enable ''
    if ("${brewPrefix}/bin/brew" | path exists) {
      $env.PATH = ($env.PATH | prepend "${brewPrefix}/bin" | prepend "${brewPrefix}/sbin")
    }'';

  # Make script available as a command
  home.packages = [
    (pkgs.writeShellScriptBin "install-brew-packages" ''
      exec ${installBrewScript}
    '')
  ];

  # Run during home-manager activation (as user, not root)
  home.activation.installHomebrew = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "Running Homebrew setup..."
    ${installBrewScript}
  '';
}
