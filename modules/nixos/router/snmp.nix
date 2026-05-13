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
    
    v3 = {
      enable = mkEnableOption "SNMPv3 support";
      user = mkOption {
        type = types.str;
        default = "router-admin";
        description = "SNMPv3 user name";
      };
      authProto = mkOption {
        type = types.enum [ "SHA" "MD5" ];
        default = "SHA";
        description = "SNMPv3 authentication protocol";
      };
      privProto = mkOption {
        type = types.enum [ "AES" "DES" ];
        default = "AES";
        description = "SNMPv3 privacy (encryption) protocol";
      };
    };

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

        # SNMPv3 Support
        ${optionalString cfg.v3.enable ''
          # SNMPv3 user configuration
          # Note: passwords must be provided via ExecStartPre or similar for full security
          # but we can set up the user structure here.
          createUser ${cfg.v3.user} ${cfg.v3.authProto} "placeholder_auth" ${cfg.v3.privProto} "placeholder_priv"
          rouser ${cfg.v3.user} priv
        ''}

        # Allow all MIBs
        view all included .1
        access notConfigGroup "" any noauth exact all none none
      '';
    };

    # Open firewall port
    services.router-firewall.trustedUdpPorts = [ 161 ];
  };
}
