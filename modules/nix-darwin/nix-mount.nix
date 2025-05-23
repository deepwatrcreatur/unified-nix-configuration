# modules/nix-darwin/nix-mount.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.custom.nix-mount;
in
{
  options.custom.nix-mount = {
    uuid = lib.mkOption {
      type = lib.types.str;
      description = "UUID of the /nix volume to mount";
      example = "12345678-1234-1234-1234-1234567890AB";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.uuid != "";
        message = "custom.nix-mount.uuid must be set for nix-mount daemon";
      }
    ];

    launchd.daemons.nix-mount = {
      serviceConfig = {
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "/usr/sbin/diskutil mount -mountPoint /nix ${cfg.uuid}"
        ];
        Label = "com.nix.mount";
        RunAtLoad = true;
        KeepAlive = false;
      };
    };

    system.activationScripts.fixLaunchDaemonPermissions = {
      text = ''
        # Log to a file for debugging
        LOG="/tmp/nix-darwin-fixLaunchDaemonPermissions.log"
        echo "$(date): Starting fixLaunchDaemonPermissions" >> "$LOG"
        PLIST="/Library/LaunchDaemons/com.nix.mount.plist"
        if [ -f "$PLIST" ]; then
          echo "$(date): Found $PLIST, setting permissions" >> "$LOG"
          ${pkgs.coreutils}/bin/chmod 644 "$PLIST" || {
            echo "$(date): Failed to chmod $PLIST" >> "$LOG"
            exit 1
          }
          ${pkgs.coreutils}/bin/chown root:wheel "$PLIST" || {
            echo "$(date): Failed to chown $PLIST" >> "$LOG"
            exit 1
          }
          echo "$(date): Successfully set permissions on $PLIST" >> "$LOG"
        else
          echo "$(date): Error: $PLIST not found" >> "$LOG"
          exit 1
        fi
      '';
      deps = [ "launchd" ]; # Run after launchd services are set up
    };
  };
}
