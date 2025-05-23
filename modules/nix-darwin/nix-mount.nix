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
          # Retry mounting every 5 seconds for up to 60 seconds
          ''for i in {1..12}; do /usr/sbin/diskutil mount -mountPoint /nix ${cfg.uuid} && exit 0; /bin/sleep 5; done; exit 1''
        ];
        Label = "com.nix.mount";
        RunAtLoad = true;
        KeepAlive = false;
        # Log errors to diagnose failures
        StandardErrorPath = "/tmp/nix-mount-error.log";
      };
    };

    # Standalone script for permissions
    environment.etc."fix-nix-mount-plist.sh" = {
      text = ''
        #!/bin/sh
        LOG="/tmp/nix-darwin-fixLaunchDaemonPermissions.log"
        echo "$(date): Running fix-nix-mount-plist.sh" >> "$LOG"
        PLIST="/Library/LaunchDaemons/com.nix.mount.plist"
        if [ -f "$PLIST" ]; then
          /bin/chmod 644 "$PLIST" 2>> "$LOG" || {
            echo "$(date): Failed to chmod $PLIST" >> "$LOG"
            exit 1
          }
          /bin/chown root:wheel "$PLIST" 2>> "$LOG" || {
            echo "$(date): Failed to chown $PLIST" >> "$LOG"
            exit 1
          }
          echo "$(date): Successfully set permissions on $PLIST" >> "$LOG"
        else
          echo "$(date): Error: $PLIST not found" >> "$LOG"
          exit 1
        fi
      '';
    };

    # Activation script runs standalone script
    system.activationScripts.fixLaunchDaemonPermissions.text = ''
      /bin/sh /run/current-system/sw/etc/fix-nix-mount-plist.sh >> /tmp/nix-darwin-fixLaunchDaemonPermissions.log 2>&1
    '';
  };
}
