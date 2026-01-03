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

    # Add /snap/bin to system PATH (appended, not prepended, to avoid breaking wrappers)
    environment.extraInit = ''
      export PATH="$PATH:/snap/bin"
    '';

    # Some portals and desktop files expect snap at /usr/bin/snap
    system.activationScripts.snap-compat = ''
      if [ ! -d /usr/bin ]; then
        mkdir -p /usr/bin
      fi
      ln -sf /run/current-system/sw/bin/snap /usr/bin/snap
    '';

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
            ];
            wants = [ "network-online.target" ];
            requires = [ "snapd.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecCondition = "${pkgs.bash}/bin/bash -c '! /run/current-system/sw/bin/snap list ${snapPkg} &>/dev/null'";
              ExecStart = "/run/current-system/sw/bin/snap install ${snapPkg}${if isClassic then " --classic" else ""}";
            };
          };
        };
      in
      builtins.listToAttrs (
        (map (pkg: mkSnapService pkg false) cfg.packages) ++
        (map (pkg: mkSnapService pkg true) cfg.classicPackages)
      );
  };
}
