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
      /bin/chmod 644 /Users/${config.system.primaryUser}/Library/LaunchAgents/com.nix.mount.plist
      /bin/chown ${config.system.primaryUser}:staff /Users/${config.system.primaryUser}/Library/LaunchAgents/com.nix.mount.plist
    '';
  };
}
