{ nix-homebrew, homebrew-core, homebrew-cask, config, lib, ... }: let
  inherit (lib) enabled mkOption types;
in {
  imports = [ nix-homebrew.darwinModules.nix-homebrew ];

  options.homebrew.hostSpecific = {
    taps = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional host-specific taps";
    };
    brews = mkOption {
      type = types.listOf types.str; 
      default = [];
      description = "Host-specific CLI tools";
    };
    casks = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Host-specific GUI applications";
    };
  };

  config = {
    homebrew = enabled {
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
      };
      
      taps = [
        "romkatv/powerlevel10k"
        "gabe565/tap" 
      ] ++ config.homebrew.hostSpecific.taps;
      
      brews = [
        "fish"
        "cmake" 
        "powerlevel10k"
        "bitwarden-cli"
      ] ++ config.homebrew.hostSpecific.brews;
      
      casks = [
        "font-fira-code"
        "ghostty"
        "rustdesk"
      ] ++ config.homebrew.hostSpecific.casks;
    };

    nix-homebrew = enabled {
      user = config.system.primaryUser;
      taps."homebrew/homebrew-core" = homebrew-core;
      taps."homebrew/homebrew-cask" = homebrew-cask;
      mutableTaps = false;
    };
  };
}
