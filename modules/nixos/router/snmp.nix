{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.router-snmp;
  optSec = import ../../../lib/optional-secrets.nix { inherit lib; };

  secrets = optSec.mkSecrets {
    snmp-community = {
      file = ../../../secrets-agenix/snmp-community.age;
      mode = "0440";
      group = "root";
    };
  };
in
{
  options.services.router-snmp = {
    enable = mkEnableOption "SNMP service for router";

    listenAddresses = mkOption {
      type = types.listOf types.str;
      default = [ "127.0.0.1" "10.10.10.1" ];
      description = "Addresses to listen on for SNMP requests";
    };

    allowedNetworks = mkOption {
      type = types.listOf types.str;
      default = [
        "10.10.0.0/16"
        "192.168.100.0/24"
      ];
      description = "Source networks allowed to query the SNMPv2c community";
    };

    location = mkOption {
      type = types.str;
      default = "Homelab";
      description = "System location for SNMP";
    };

    contact = mkOption {
      type = types.str;
      default = "deepwatrcreatur@gmail.com";
      description = "System contact for SNMP";
    };
  };

  config = mkIf cfg.enable {
    age.secrets = secrets.definitions;

    systemd.services.snmpd = {
      description = "Simple Network Management Protocol (SNMP) daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        set -euo pipefail
        umask 077

        if [ ! -r "${secrets.path "snmp-community"}" ]; then
          echo "Missing SNMP community secret: ${secrets.path "snmp-community"}" >&2
          exit 1
        fi

        community="$(${pkgs.coreutils}/bin/cat "${secrets.path "snmp-community"}")"

        cat > /run/snmpd/snmpd.conf <<'EOF'
        # Listen on the router-local addresses configured by Nix.
        ${concatMapStringsSep "\n" (addr: "agentAddress udp:${addr}:161") cfg.listenAddresses}

        sysLocation ${cfg.location}
        sysContact ${cfg.contact}
        EOF

        ${concatMapStringsSep "\n" (cidr: ''
          printf 'rocommunity %s %s\n' "$community" "${cidr}" >> /run/snmpd/snmpd.conf
        '') cfg.allowedNetworks}
      '';
      serviceConfig = {
        RuntimeDirectory = "snmpd";
        ExecStart = "${lib.getExe' pkgs.net-snmp "snmpd"} -f -Lo -c /run/snmpd/snmpd.conf";
        Restart = "on-failure";
      };
    };

    services.router-firewall.trustedUdpPorts = [ 161 ];
  };
}
