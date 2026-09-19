# overlays/cosmic.nix
# Use COSMIC packages from nixpkgs-unstable (v1.5.0) to eliminate
# memory leaks and compositor stability issues present in older versions.
{ inputs, commonNixpkgsConfig }:

[
  (final: prev:
    let
      unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system};
    in
    {
      inherit (unstable)
        cosmic-app-library
        cosmic-applets
        cosmic-bg
        cosmic-comp
        cosmic-design-demo
        cosmic-edit
        cosmic-files
        cosmic-greeter
        cosmic-icons
        cosmic-idle
        cosmic-initial-setup
        cosmic-launcher
        cosmic-notifications
        cosmic-osd
        cosmic-panel
        cosmic-player
        cosmic-protocols
        cosmic-randr
        cosmic-reader
        cosmic-screenshot
        cosmic-session
        cosmic-settings
        cosmic-settings-daemon
        cosmic-sound-theme
        cosmic-store
        cosmic-tasks
        cosmic-term
        cosmic-wallpapers
        cosmic-workspaces-epoch
        xdg-desktop-portal-cosmic;
    }
  )
]

