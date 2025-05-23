# modules/nix-darwin/nix-mount.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.custom.nix-mount;
  fixPermissionsScript = pkgs.writeFile {
    name = "fix-launch-agent-permissions.sh";
    text = ''
      #!/bin/sh
      LOG="/tmp/nix-darwin-fixLaunchAgentPermissions.log"
      echo "$(date): Starting fixLaunchAgentPermissions" >> "$LOG"
      PLIST="/Users/${config.system.primaryUser}/Library/LaunchAgents/com.nix.mount.plist"
      sleep 5  # Increased delay to ensure plist creation
      if [ -f "$PLIST" ]; then
        echo "$(date): Found $PLIST, setting permissions" >> "$LOG"
        sudo ${pkgs.coreutils}/bin/chmod 644 "$PLIST" 2>> "$LOG" || {
          echo "$(date): Failed to chmod $PLIST" >> "$LOG"
          exit 1
        }
        sudo ${pkgs.coreutils}/bin/chown ${config.system.primaryUser}:staff "$PLIST" 2>> "$LOG" || {
          echo "$(date): Failed to chown $PLIST" >> "$LOG"
          exit 1
        }
        echo "$(date): Successfully set permissions on $PLIST" >> "$LOG"
      else
        echo "$(date): Error: $PLIST not found after 5 seconds" >> "$LOG"
        exit 1
      fi
    '';
    executable = true;
  };
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
        assertion = config.system.primaryUser != "";
        message = "system.primaryUser must be set for nix-mount launch agent";
      }
      {
        assertion = cfg.uuid != "";
        message = "custom.nix-mount.uuid must be set for nix-mount launch agent";
      }
    ];

    launchd.user.agents.nix-mount = {
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

    system.activationScripts.fixLaunchAgentPermissions.text = ''
      ${fixPermissionsScript}
    '';
  };
}
