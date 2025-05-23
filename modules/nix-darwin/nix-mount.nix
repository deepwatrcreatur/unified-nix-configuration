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
    # Assertions to catch misconfigurations
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

    # Use home-manager to manage the plist file for the primary user
    home-manager.users.${config.system.primaryUser} = {
      home.file."Library/LaunchAgents/com.nix.mount.plist" = {
        enable = true;
        text = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
              <key>Label</key>
              <string>com.nix.mount</string>
              <key>ProgramArguments</key>
              <array>
                  <string>/bin/sh</string>
                  <string>-c</string>
                  <string>/usr/sbin/diskutil mount -mountPoint /nix ${cfg.uuid}</string>
              </array>
              <key>RunAtLoad</key>
              <true/>
              <key>KeepAlive</key>
              <false/>
          </dict>
          </plist>
        '';
      };

      # Post-activation script to fix permissions
      home.activation.fixLaunchAgentPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
        ${pkgs.coreutils}/bin/chmod 644 /Users/${config.system.primaryUser}/Library/LaunchAgents/com.nix.mount.plist
        ${pkgs.coreutils}/bin/chown ${config.system.primaryUser}:staff /Users/${config.system.primaryUser}/Library/LaunchAgents/com.nix.mount.plist
      '';
    };
  };
}
