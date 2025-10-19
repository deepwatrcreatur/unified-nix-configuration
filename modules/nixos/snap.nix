{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myModules.snap;
in
{
  options.myModules.snap = {
    enable = mkEnableOption "snap package manager support";

    packages = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of snap packages to install";
      example = [ "raindrop" "spotify" ];
    };
  };

  config = mkIf cfg.enable {
    # Enable snapd service
    services.snap.enable = true;

    # Install snap packages using systemd oneshot services
    # This runs after snapd is started
    systemd.services = builtins.listToAttrs (map (snapPkg: {
      name = "snap-install-${snapPkg}";
      value = {
        description = "Install snap package: ${snapPkg}";
        after = [ "snapd.service" "snapd.socket" ];
        requires = [ "snapd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecCondition = "${pkgs.bash}/bin/bash -c '! ${pkgs.snap}/bin/snap list ${snapPkg} &>/dev/null'";
          ExecStart = "${pkgs.snap}/bin/snap install ${snapPkg}";
        };
      };
    }) cfg.packages);
  };
}
