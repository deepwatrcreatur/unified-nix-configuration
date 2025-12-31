# modules/nix-darwin/default.nix (rename from common-darwin.nix)
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Auto-import all .nix files and directories from common directory
  commonDir = ./common;
  commonImports = lib.mapAttrsToList
    (name: _: commonDir + "/${name}")
    (lib.filterAttrs
      (name: type: (type == "regular" && lib.hasSuffix ".nix" name) || type == "directory")
      (builtins.readDir commonDir)
    );
in
{
  imports = commonImports
  ++ [
    # Explicit imports that don't belong in common
    ../wezterm-config.nix
    ./system-limits.nix
    # ../activation-scripts
  ];

  # Import darwin-specific home-manager modules for all users
  home-manager.sharedModules = [
    ../home-manager/attic-client-darwin.nix
  ];

  # macOS-specific wezterm configuration
  programs.wezterm.extraConfig = lib.mkAfter ''
    -- Default program: launch zellij with nushell as default shell (macOS path)
    config.default_prog = { wezterm.home_dir .. '/.cargo/bin/zellij', '-l', 'welcome' }
  '';

  nixpkgs.config.allowUnfree = true;

  system.defaults = {
    NSGlobalDomain = {
      NSNavPanelExpandedStateForSaveMode = true;
      NSDocumentSaveNewDocumentsToCloud = false;
    };
    LaunchServices = {
      LSQuarantine = false;
    };
  };

  system.activationScripts.postActivation.text = ''
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
  '';

  
}
