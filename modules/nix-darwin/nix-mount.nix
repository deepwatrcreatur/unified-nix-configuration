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
          # Initial 5-second delay, retry every 5 seconds for 60 seconds
          ''/bin/sleep 5; for i in {1..12}; do /usr/sbin/diskutil mount -mountPoint /nix ${cfg.uuid} && exit 0; /bin/sleep 5; done; exit 1''
        ];
        Label = "com.nix.mount";
        RunAtLoad = true;
        KeepAlive = false;
        StandardErrorPath = "/tmp/nix-mount-error.log";
        StandardOutPath = "/tmp/nix-mount-out.log";
      };
    };

    system.activationScripts.fixLaunchDaemonPermissions.text = ''
      LOG="/tmp/nix-darwin-activation.log"
      echo "$(date): Starting fixLaunchDaemonPermissions" >> "$LOG"
      PLIST="/Library/LaunchDaemons/com.nix.mount.plist"
      # Wait up to 5 seconds for plist to appear
      for i in {1..5}; do
        if [ -f "$PLIST" ]; then
          echo "$(date): Found $PLIST, setting permissions" >> "$LOG"
          /bin/chmod u+w "$PLIST" 2>> "$LOG" || {
            echo "$(date): Failed to chmod u+w $PLIST" >> "$LOG"
            exit 1
          }
          echo "$(date): Successfully set permissions on $PLIST" >> "$LOG"
          exit 0
        fi
        echo "$(date): Waiting for $PLIST ($i/5)" >> "$LOG"
        sleep 1
      done
      echo "$(date): Error: $PLIST not found after 5 seconds" >> "$LOG"
      exit 1
    '';
  };
}
