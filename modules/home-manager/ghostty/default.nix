{ pkgs, lib, config, ... }:
let
  shellCommand = if config.platform.isDarwin then "${config.platform.homebrewPrefix}/bin/fish" else "${pkgs.fish}/bin/fish";

  configFile = pkgs.substitute {
    src = ./config;
    substitutions = [
      "--replace"
      "@shellCommand@"
      shellCommand
    ];
  };

in
{
  # Set environment variables for system integration
  home.sessionVariables =
    lib.optionalAttrs config.platform.isLinux { TERMINAL = "ghostty"; }
    // lib.optionalAttrs config.platform.isDarwin { TERM_PROGRAM = "ghostty"; };

  # Install Ghostty on Linux (handle macOS separately if needed)
  home.packages = lib.optionals config.platform.isLinux [
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
    createGhosttyDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/.config/ghostty/themes
      $DRY_RUN_CMD mkdir -p $HOME/.config/ghostty
    '';
  };

  programs.ghostty = {
    enable = true;
    package = lib.mkIf config.platform.isDarwin null;
    installBatSyntax = !config.platform.isDarwin;
    # Don't set settings here since we're using the config file
  };

  programs.fish.enable = lib.mkDefault true;

  # Optional: Add ghostty to desktop entries on Linux
  xdg.desktopEntries = lib.mkIf config.platform.isLinux {
    ghostty = {
      name = "Ghostty";
      comment = "Fast, feature-rich, and cross-platform terminal emulator";
      icon = "ghostty";
      exec = "${pkgs.ghostty}/bin/ghostty";
      categories = [
        "System"
        "TerminalEmulator"
      ];
      terminal = false;
    };
  };
}
