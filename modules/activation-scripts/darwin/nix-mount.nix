{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.activation-scripts.darwin.nix-mount;
  
  fixLaunchDaemonScript = pkgs.writeShellScript "fix-launchd-permissions.sh" ''
    # Fix LaunchDaemon permissions
    /bin/sh /run/current-system/sw/etc/fix-nix-mount-plist.sh
  '';
  
  updateDeterminateScript = uuid: pkgs.writeShellScript "update-determinate-nix.sh" ''
    # Update determinate nix mount script with current UUID
    if [ -f /usr/local/bin/mount-nix-ssd.sh ]; then
      echo "Updating determinate nix mount script with UUID: ${uuid}"
      /usr/bin/sed -i "" "s/SSD_UUID=\".*\"/SSD_UUID=\"${uuid}\"/" /usr/local/bin/mount-nix-ssd.sh || true
    fi
  '';
in
{
  options.custom.activation-scripts.darwin.nix-mount = {
    enable = lib.mkEnableOption "Nix mount activation scripts for macOS";
    
    uuid = lib.mkOption {
      type = lib.types.str;
      description = "UUID of the /nix volume to mount";
      example = "12345678-1234-1234-1234-1234567890AB";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.uuid != "";
        message = "custom.activation-scripts.darwin.nix-mount.uuid must be set";
      }
    ];

    system.activationScripts.fixLaunchDaemonPermissions.text = lib.mkAfter ''
      echo "Running fix LaunchDaemon permissions script..."
      ${fixLaunchDaemonScript}
    '';

    system.activationScripts.updateDeterminateNixScript.text = lib.mkAfter ''
      echo "Running update determinate nix script..."
      ${updateDeterminateScript cfg.uuid}
    '';
  };
}