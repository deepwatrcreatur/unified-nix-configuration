# modules/nix-darwin/common-darwin.nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./nix-mount.nix
  ];
  
  nixpkgs.config.allowUnfree = true;
  
  system.defaults.finder.AppleShowAllExtensions = true;
  
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
  
  # Also set via system activation script as a fallback
  system.activationScripts.extraActivation.text = ''
    # Set file descriptor limits
    launchctl limit maxfiles 65536 200000 2>/dev/null || true
  '';
}
