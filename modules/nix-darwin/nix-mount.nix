# modules/nix-darwin/nix-mount.nix
{ config, lib, ... }:
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
    # Define launchd.user.agents for activation
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
    };
  };
}
