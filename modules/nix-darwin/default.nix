# modules/nix-darwin/default.nix (rename from common-darwin.nix)
{ config, pkgs, lib, ... }:
let
  # Helper to import all .nix files AND directories from common directory
  commonDir = ./common;
  commonItems = builtins.readDir commonDir;
  commonModules = lib.filterAttrs (name: type: 
    (type == "regular" && lib.hasSuffix ".nix" name) || 
    type == "directory"
  ) commonItems;
  commonImports = lib.mapAttrsToList (name: _: commonDir + "/${name}") commonModules;
in
{
  imports = [
    # Auto-import all common Darwin modules
  ] ++ commonImports ++ [
    # Explicit imports that don't belong in common
    ../wezterm-config.nix
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

  # Increase file descriptor limits for Nix builds to 200000
  # nix-darwin doesn't have a built-in option for this, so we use launchd daemon approach
  # This sets both soft and hard limits via launchctl at boot time
  launchd.daemons."org.nix-community.limit-maxfiles" = {
    script = "/bin/launchctl limit maxfiles 65536 200000";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/var/log/nix-daemon-limit.log";
      StandardErrorPath = "/var/log/nix-daemon-limit.log";
    };
  };

  system.defaults = {
    NSGlobalDomain = {
      NSNavPanelExpandedStateForSaveMode = true;
      NSDocumentSaveNewDocumentsToCloud = false;
    };
    LaunchServices = {
      LSQuarantine = false;
    };
  };

  # Also set limits during system activation as a fallback
  system.activationScripts.extraActivation.text = ''
    echo "Setting launchctl file descriptor limits..."
    /bin/launchctl limit maxfiles 65536 200000 2>/dev/null || true
  '';

  system.activationScripts.postActivation.text = ''
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
  '';
}
