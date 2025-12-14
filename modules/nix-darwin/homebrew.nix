# modules/nix-darwin/homebrew.nix
{
  nix-homebrew,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  imports = [ nix-homebrew.darwinModules.nix-homebrew ];

  options.homebrew.hostSpecific = {
    taps = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional host-specific taps";
    };
    brews = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Host-specific CLI tools";
    };
    casks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Host-specific GUI applications";
    };
  };

  config = {
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = false; # Temporarily disabled due to git permission issues
        cleanup = "uninstall"; # Changed from "zap" to avoid git operations
      };
      taps = (import ../common-brew-packages.nix).taps
        ++ config.homebrew.hostSpecific.taps;
      brews = [
        "cmake"
        "fish"
        "powerlevel10k"
        "bitwarden-cli"
      ]
      ++ (import ../common-brew-packages.nix).brews
      ++ config.homebrew.hostSpecific.brews;
      casks = [
        "coteditor"
        "font-fira-code"
        "ghostty"
        "maccy"
        "raycast"
        "rustdesk"
      ]
      ++ (import ../common-brew-packages.nix).casks
      ++ config.homebrew.hostSpecific.casks;
    };

    nix-homebrew = {
      enable = true;
      user = config.system.primaryUser;
      autoMigrate = true;
      mutableTaps = true;
    };
  };
}
