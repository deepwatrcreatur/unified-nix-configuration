{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.xbar;
in
{
  # Define an option to enable/disable xbar
  options.programs.xbar = {
    enable = mkEnableOption "xbar, a macOS menu bar customization tool";
  };

  config = mkIf cfg.enable {
    # Append xbar to home.packages without overwriting existing packages
    home.packages = [ pkgs.xbar ];

    # Configure launchd to start xbar on login
    launchd.agents.xbar = {
      enable = true;
      config = {
        ProgramArguments = [ "${pkgs.xbar}/Applications/xbar.app/Contents/MacOS/xbar" ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/xbar.log";
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/xbar.log";
      };
    };
  };
}
