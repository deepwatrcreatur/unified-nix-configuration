# modules/home-manager/common/platform.nix
# Provides platform detection options for cross-platform home-manager modules
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Detect platform from pkgs.stdenv
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Homebrew prefix varies by architecture on macOS
  homebrewPrefix =
    if isDarwin then
      (if pkgs.stdenv.hostPlatform.isAarch64 then "/opt/homebrew" else "/usr/local")
    else
      "/home/linuxbrew/.linuxbrew"; # Linuxbrew path for Linux
in
{
  options.platform = {
    isDarwin = lib.mkOption {
      type = lib.types.bool;
      default = isDarwin;
      readOnly = true;
      description = "Whether the current platform is macOS/Darwin";
    };

    isLinux = lib.mkOption {
      type = lib.types.bool;
      default = isLinux;
      readOnly = true;
      description = "Whether the current platform is Linux";
    };

    homebrewPrefix = lib.mkOption {
      type = lib.types.str;
      default = homebrewPrefix;
      description = "The Homebrew installation prefix for the current platform";
    };
  };
}
