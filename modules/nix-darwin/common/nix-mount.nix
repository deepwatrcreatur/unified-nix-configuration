# modules/nix-darwin/nix-mount.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.custom.nix-mount;

  # Create an executable script in the Nix store
  fixNixMountPlistScript = pkgs.runCommand "fix-nix-mount-plist.sh" {
    src = ./fix-nix-mount-plist.sh;
  } ''
    mkdir -p $out
    cp $src $out/fix-nix-mount-plist.sh
    chmod +x $out/fix-nix-mount-plist.sh
  '';
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
          ''
            LOGFILE="/Users/deepwatrcreatur/nix-mount.log"
            echo "Starting nix-mount script" > $LOGFILE
            /bin/sleep 5
            for i in {1..12}; do
              echo "Attempt $i" >> $LOGFILE
              /usr/sbin/diskutil mount -mountPoint /nix ${cfg.uuid} >> $LOGFILE 2>&1
              if [ $? -eq 0 ]; then
                echo "Mount successful" >> $LOGFILE
                exit 0
              fi
              echo "Mount failed, sleeping 5s" >> $LOGFILE
              /bin/sleep 5
            done
            echo "Mount failed after 12 attempts" >> $LOGFILE
            exit 1
          ''
        ];
        Label = "com.nix.mount";
        RunAtLoad = true;
        KeepAlive = false;
      };
    };

    environment.etc."fix-nix-mount-plist.sh".source = "${fixNixMountPlistScript}/fix-nix-mount-plist.sh";

    system.activationScripts.fixLaunchDaemonPermissions.text = ''
      /bin/sh /run/current-system/sw/etc/fix-nix-mount-plist.sh
    '';

    system.activationScripts.updateDeterminateNixScript.text = ''
      # Update determinate nix mount script with current UUID
      if [ -f /usr/local/bin/mount-nix-ssd.sh ]; then
        echo "Updating determinate nix mount script with UUID: ${cfg.uuid}"
        /usr/bin/sed -i "" "s/SSD_UUID=\".*\"/SSD_UUID=\"${cfg.uuid}\"/" /usr/local/bin/mount-nix-ssd.sh || true
      fi
    '';
  };
}
