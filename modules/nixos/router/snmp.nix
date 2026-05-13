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

    services.snmpd = {
      enable = true;
      extraConfig = ''
        # Listen on specified addresses
        ${concatMapStringsSep "\n" (addr: "agentAddress udp:${addr}:161") cfg.listenAddresses}

        # System info
        sysLocation ${cfg.location}
        sysContact ${cfg.contact}

        # Read-only community from secret (if exists) or default to 'public'
        ${if secrets.exists "snmp-community" 
          then "rocommunity `cat ${secrets.path "snmp-community"}`" 
          else "rocommunity public"}

        # Allow all MIBs
        view all included .1
        access notConfigGroup "" any noauth exact all none none
      '';
    };

    # Open firewall port
    services.router-firewall.trustedUdpPorts = [ 161 ];
  };
}
