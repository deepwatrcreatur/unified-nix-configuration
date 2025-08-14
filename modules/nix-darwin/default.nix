# modules/nix-darwin/common-darwin.nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./nix-mount.nix
    ./accessibility.nix
    ./clock.nix
    ./dock.nix
    ./finder.nix
    ./hammerspoon.nix
    ./localization.nix
    ./maccy.nix
    ./netbios.nix
    ./screensaver.nix
    ./trackpad.nix
    ../wezterm-config.nix
  ];
  
  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = with pkgs; [
    watch
  ];
  
  # Increase file descriptor limits for Nix builds
  launchd.daemons.limit-maxfiles = {
    script = ''
      launchctl limit maxfiles 65536 200000
    '';
    serviceConfig = {
      Label = "limit.maxfiles";
      RunAtLoad = true;
      KeepAlive = false;
    };
  };
  
  system.defaults = {
    NSGlobalDomain = {
      NSNavPanelExpandedStateForSaveMode = true; # Expand save dialogs by default
      NSDocumentSaveNewDocumentsToCloud = false; # Save documents locally by default
    };
    LaunchServices = {
      LSQuarantine = false;
    };
  };
  
  # Also set via system activation script as a fallback
  system.activationScripts.extraActivation.text = ''
    # Set file descriptor limits
    launchctl limit maxfiles 65536 200000 2>/dev/null || true
  '';

  # Activation script for unsupported settings
  system.activationScripts.postActivation.text = ''
    # Disable automatic software updates
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
    /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
  '';
}

