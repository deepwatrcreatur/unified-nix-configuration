{ pkgs, lib, ... }:
{
  # Set environment variables for system integration
  home.sessionVariables = {
    TERMINAL = lib.mkIf pkgs.stdenv.isLinux "ghostty";
    TERM_PROGRAM = lib.mkIf pkgs.stdenv.isDarwin "ghostty";
  };

  # Install Ghostty on Linux (handle macOS separately if needed)
  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.ghostty
  ];

  xdg.configFile."ghostty/config" = {
    source = ./config;
  };

  # Enhanced theme management
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

  # Platform-specific shell integration setup
  programs.fish.enable = lib.mkDefault true; # Since you use fish integration
  
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
