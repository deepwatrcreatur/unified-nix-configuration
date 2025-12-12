{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Increase file descriptor limits for Nix builds to 200000
  # nix-darwin doesn't have a built-in maxOpenFiles option, so we use multiple approaches

  # Set via nix daemon configuration (preferred method)
  nix.settings.max-open-files = 200000;

  # Also set via launchd for system-wide limits (fallback approach)
  launchd.daemons."org.nix-community.limit-maxfiles" = {
    script = "/bin/launchctl limit maxfiles 65536 200000";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/var/log/nix-daemon-limit.log";
      StandardErrorPath = "/var/log/nix-daemon-limit.log";
    };
  };

  
}
