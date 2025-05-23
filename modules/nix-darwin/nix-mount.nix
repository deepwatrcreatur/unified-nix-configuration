# modules/nix-mount.nix
{ config, lib, ... }:
let
  # Define an option for the UUID
  cfg = config.custom.nix-mount;
in
{
  # Declare a configuration option for the UUID
  options.custom.nix-mount = {
    uuid = lib.mkOption {
      type = lib.types.str;
      description = "UUID of the /nix volume to mount";
      example = "12345678-1234-1234-1234-1234567890AB";
    };
  };

  # Define the launchd agent
  config = {
    # Ensure /nix is in synthetic.conf
    environment.etc."synthetic.conf".text = ''
      nix
    '';

    launchd.agents.nix-mount = {
      enable = true;
      config = {
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
  };
}
