{ config, pkgs, lib, ... }:

{
  # Increase file descriptor limits for Nix builds to 200000
  # nix-darwin doesn't have a built-in maxOpenFiles option, so we use launchd daemon approach
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

  # Also set limits during system activation as a fallback
  system.activationScripts.extraActivation.text = ''
    echo "Setting launchctl file descriptor limits..."
    /bin/launchctl limit maxfiles 65536 200000 2>/dev/null || true
  '';
}
