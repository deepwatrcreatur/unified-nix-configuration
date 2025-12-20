# modules/common/platform-detection.nix - Platform detection utilities
{ lib, ... }:

let
  inherit (lib) mkIf mkDefault;
in
{
  # Platform detection options available to all modules
  options = {
    platform = {
      isDarwin = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the system is Darwin/macOS";
      };

      isNixOS = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the system is NixOS";
      };

      isLinux = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the system is Linux (non-NixOS)";
      };

      homebrewPrefix = lib.mkOption {
        type = lib.types.str;
        default = "/usr/local";
        description = "Homebrew installation prefix path";
      };
    };
  };

  config = {
    # Auto-detect platform
    platform.isDarwin = mkDefault (pkgs.stdenv.hostPlatform.isDarwin);
    platform.isNixOS = mkDefault (builtins.pathExists "/etc/nixos");
    platform.isLinux = mkDefault (pkgs.stdenv.hostPlatform.isLinux && !config.platform.isNixOS);
    
    # Set Homebrew prefix based on platform
    platform.homebrewPrefix = mkDefault (
      if config.platform.isDarwin then "/opt/homebrew"
      else if config.platform.isLinux then "/usr/local"
      else "/usr/local"
    );
  };

  # Export helper functions for use in other modules
  _module.args.pkgs = pkgs // {
    platformHelpers = {
      # Get Homebrew gcc executable path
      homebrewGcc = let
        prefix = config.platform.homebrewPrefix;
        gccVersions = ["15" "14" "13" "12" "11"];
        findGcc = version: "${prefix}/bin/gcc-${version}";
      in
        # Find first available gcc version
        lib.findFirst (path: builtins.pathExists path) 
          "${pkgs.gcc}/bin/gcc" 
          (map findGcc gccVersions);

      # Get Homebrew bin directory
      homebrewBin = config.platform.homebrewPrefix + "/bin";
    };
  };
}
