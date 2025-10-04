{ pkgs, lib, ... }:
let
  configFile = 
    if pkgs.stdenv.isDarwin then ./config-darwin
    else pkgs.substitute({
      src = ./config-linux;
      substitutions = {
        "@fishPath@" = pkgs.fish;
      };
    });
in
{
  # Set environment variables for system integration
  home.sessionVariables = 
    lib.optionalAttrs pkgs.stdenv.isLinux { TERMINAL = "ghostty"; } //
    lib.optionalAttrs pkgs.stdenv.isDarwin { TERM_PROGRAM = "ghostty"; };

  # Install Ghostty on Linux (handle macOS separately if needed)
  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.ghostty
  ];

  xdg.configFile."ghostty/config" = {
    source = configFile;
  };

  xdg.configFile."ghostty/themes/Sugarplum" = {
    source = ./themes/Sugarplum;
  };

  # Ensure the themes and config directories exist
  home.activation = {
    createGhosttyDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $HOME/.config/ghostty/themes
      $DRY_RUN_CMD mkdir -p $HOME/.config/ghostty
    '';
  };

  programs.ghostty = {
    enable = true;
    package = lib.mkIf pkgs.stdenv.isDarwin null;
    installBatSyntax = !pkgs.stdenv.isDarwin;
    # Don't set settings here since we're using the config file
  };

  programs.fish.enable = lib.mkDefault true; 
  
  # Optional: Add ghostty to desktop entries on Linux
  xdg.desktopEntries = lib.mkIf pkgs.stdenv.isLinux {
    ghostty = {
      name = "Ghostty";
      comment = "Fast, feature-rich, and cross-platform terminal emulator";
      icon = "ghostty";
      exec = "ghostty";
      categories = [ "System" "TerminalEmulator" ];
      terminal = false;
    };
  };
}
