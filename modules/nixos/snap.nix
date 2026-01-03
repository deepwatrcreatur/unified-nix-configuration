{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.myModules.snap;
in
{
  options.myModules.snap = {
    enable = mkEnableOption "snap package manager support";

    packages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of snap packages to install with strict confinement";
      example = [
        "raindrop"
        "spotify"
      ];
    };

    classicPackages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of snap packages to install with --classic confinement";
      example = [
        "icloud-for-linux"
        "code"
      ];
    };
  };

  config = mkIf cfg.enable {
    # Enable snapd service
    services.snap.enable = true;

    # Add /snap/bin to system PATH and ensure snap is available
    environment.extraInit = ''
      # Ensure snap paths are available
      export PATH="$PATH:/snap/bin:/var/lib/snapd/snap/bin"
      # Ensure snap can find its binaries
      export SNAP=/snap
      export SNAP_COMMON=/var/snap
      export SNAP_DATA=/var/lib/snapd
    '';

    # Some portals and desktop files expect snap at /usr/bin/snap
    system.activationScripts.snap-compat = ''
      # Create directories if they don't exist
      mkdir -p /usr/bin /usr/local/bin

      # Create symlinks for snap binary in common locations
      ln -sf /run/current-system/sw/bin/snap /usr/bin/snap
      ln -sf /run/current-system/sw/bin/snap /usr/local/bin/snap

      # Ensure snap directories exist
      mkdir -p /snap /var/lib/snapd/snap

      # Fix snap permissions for portal access
      chmod 755 /usr/bin/snap
    '';

    # XDG portal configuration for snap access
    xdg.portal.config = {
      common = {
        # Ensure snap can be used by portals
        preferred = "gtk;cosmic";
      };
    };

    # Install snap packages using systemd oneshot services
    # This runs after snapd and network are available
    systemd.services =
      let
        mkSnapService = snapPkg: isClassic: {
          name = "snap-install-${snapPkg}";
          value = {
            description = "Install snap package: ${snapPkg}${if isClassic then " (classic)" else ""}";
            after = [
              "snapd.service"
              "snapd.socket"
              "network-online.target"
              "graphical-session-pre.target"
            ];
            wants = [ "network-online.target" ];
            requires = [ "snapd.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              Environment = "PATH=/run/current-system/sw/bin:/usr/bin:/usr/local/bin:/snap/bin:/var/lib/snapd/snap/bin";
              ExecCondition = "${pkgs.bash}/bin/bash -c '! /run/current-system/sw/bin/snap list ${snapPkg} &>/dev/null'";
              ExecStart = "/run/current-system/sw/bin/snap install ${snapPkg}${
                if isClassic then " --classic" else ""
              }";
              ExecStartPost = "${pkgs.bash}/bin/bash -c 'sleep 2 && /run/current-system/sw/bin/snap refresh ${snapPkg} || true'";
            };
          };
        };
      in
      builtins.listToAttrs (
        (map (pkg: mkSnapService pkg false) cfg.packages)
        ++ (map (pkg: mkSnapService pkg true) cfg.classicPackages)
      );
  };
}
