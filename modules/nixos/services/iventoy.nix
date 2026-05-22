{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.iventoy;
  defaultPackage = pkgs.callPackage ../../../pkgs/iventoy-free.nix { };
  runtimeLibraryPath = lib.makeLibraryPath [
    pkgs.glib
    pkgs.libevent
    pkgs.wimlib
    pkgs.hivex
  ];
in
{
  options.services.iventoy = {
    enable = lib.mkEnableOption "iVentoy PXE ISO menu server";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      description = "iVentoy package to run.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/iventoy";
      description = "Writable iVentoy runtime directory.";
    };

    isoDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/pxe/images";
      description = "Directory containing ISO files shown in the iVentoy boot menu.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open iVentoy HTTP, web UI, TFTP, and PXE proxy ports in the NixOS firewall.";
    };

    httpPort = lib.mkOption {
      type = lib.types.port;
      default = 16000;
      description = "iVentoy HTTP boot content port.";
    };

    webUiPort = lib.mkOption {
      type = lib.types.port;
      default = 26000;
      description = "iVentoy web UI port.";
    };

    tftpPort = lib.mkOption {
      type = lib.types.port;
      default = 69;
      description = "iVentoy TFTP port.";
    };

    proxyDhcpPort = lib.mkOption {
      type = lib.types.port;
      default = 4011;
      description = "iVentoy PXE proxy DHCP port.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 root root -"
      "d ${cfg.isoDir} 0755 root root -"
    ];

    systemd.services.iventoy = {
      description = "iVentoy PXE ISO menu server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.RequiresMountsFor = cfg.isoDir;

      path = with pkgs; [
        bash
        coreutils
        gnugrep
        procps
      ];

      preStart = ''
        set -euo pipefail

        install -d -m 0755 "${cfg.stateDir}"
        install -d -m 0755 "${cfg.stateDir}/data" "${cfg.stateDir}/log/history"

        rm -rf "${cfg.stateDir}/lib" "${cfg.stateDir}/doc"
        cp -a "${cfg.package}/share/iventoy/lib" "${cfg.stateDir}/lib"
        cp -a "${cfg.package}/share/iventoy/doc" "${cfg.stateDir}/doc"
        cp -a "${cfg.package}/share/iventoy/iventoy.sh" "${cfg.stateDir}/iventoy.sh"

        if [ ! -e "${cfg.stateDir}/user" ]; then
          cp -a "${cfg.package}/share/iventoy/user" "${cfg.stateDir}/user"
        fi
        if [ ! -e "${cfg.stateDir}/data/iventoy.dat" ]; then
          cp -a "${cfg.package}/share/iventoy/data/iventoy.dat" "${cfg.stateDir}/data/iventoy.dat"
        fi
        if [ ! -e "${cfg.stateDir}/data/mac.db" ]; then
          cp -a "${cfg.package}/share/iventoy/data/mac.db" "${cfg.stateDir}/data/mac.db"
        fi

        rm -rf "${cfg.stateDir}/iso"
        ln -s "${cfg.isoDir}" "${cfg.stateDir}/iso"
      '';

      serviceConfig = {
        Type = "simple";
        WorkingDirectory = cfg.stateDir;
        Environment = [
          "IVENTOY_API_ALL=1"
          "IVENTOY_AUTO_RUN=1"
          "IVENTOY_NO_DAEMON_MODE=1"
        ];
        ExecStart = "${pkgs.glibc}/lib/ld-linux-x86-64.so.2 --library-path ${cfg.stateDir}/lib/lin64:${runtimeLibraryPath} ${cfg.stateDir}/lib/iventoy";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [
        cfg.httpPort
        cfg.webUiPort
      ];
      allowedUDPPorts = [
        cfg.tftpPort
        cfg.proxyDhcpPort
      ];
    };
  };
}
