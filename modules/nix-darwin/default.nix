# modules/nix-darwin/default.nix (rename from common-darwin.nix)
{
  config,
  pkgs,
  lib,
  ...
}:
let
  commonDir = ./common;
  moduleLoading = import ../../lib/flake/module-loading.nix { inherit lib; };
in
{
  imports =
    (moduleLoading.mkAutoImport {
      dir = commonDir;
    })
    ++ [
      # Explicit imports that don't belong in common
      ../wezterm-config.nix
      ./system-limits.nix
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
