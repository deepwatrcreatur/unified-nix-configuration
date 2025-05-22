{ config, lib, pkgs, ... }:

with lib;

{
  options.modules.homeAssistant = {
    enable = mkEnableOption "Home Assistant service";
    
    configDir = mkOption {
      type = types.str;
      default = "/var/lib/hass";
      description = "Directory to store Home Assistant configuration";
    };
    
    latitude = mkOption {
      type = types.str;
      default = "40.7128";
      description = "Latitude coordinate for your location";
    };
    
    longitude = mkOption {
      type = types.str;
      default = "-74.0060";
      description = "Longitude coordinate for your location";
    };
    
    timeZone = mkOption {
      type = types.str;
      default = "America/Toronto";
      description = "Your timezone";
    };
    
    unitSystem = mkOption {
      type = types.enum [ "metric" "imperial" ];
      default = "metric";
      description = "Unit system to use";
    };
    
    extraComponents = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional Home Assistant components to enable";
    };
    
    extraPackages = mkOption {
      type = types.functionTo (types.listOf types.package);
      default = py: [];
      description = "Extra Python packages for Home Assistant";
    };
    
    # TP-Link Kasa configuration
    tplink = {
      enable = mkEnableOption "TP-Link Kasa integration";
      discoveryEnabled = mkOption {
        type = types.bool;
        default = true;
        description = "Enable automatic discovery of TP-Link devices";
      };
      devices = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Manual configuration of TP-Link devices with IPs/hostnames";
        example = literalExpression ''
          {
            "Kitchen Plug" = "10.10.14.12";
            "Living Room Plug" = "10.10.14.13";
          }
        '';
      };
    };
    
    # Reolink camera configuration 
    reolink = {
      enable = mkEnableOption "Reolink camera integration";
      cameras = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            host = mkOption {
              type = types.str;
              description = "IP address or hostname of the Reolink camera";
            };
            port = mkOption {
              type = types.port;
              default = 80;
              description = "HTTP port of the camera";
            };
            username = mkOption {
              type = types.str;
              description = "Username for camera authentication";
            };
            password = mkOption {
              type = types.str;
              description = "Password for camera authentication";
            };
            channel = mkOption {
              type = types.int;
              default = 0;
              description = "Channel of the camera (usually 0 for standalone cameras)";
            };
            stream = mkOption {
              type = types.enum ["main" "sub" "ext"];
              default = "sub";
              description = "Stream type (main=HD, sub=SD, ext=extended)";
            };
          };
        });
        default = {};
        description = "Reolink cameras configuration";
      };
    };
  };

  config = mkIf config.modules.homeAssistant.enable {
    services.home-assistant = {
      enable = true;
      
      openFirewall = true;
      
      config = {
        homeassistant = {
          name = "Home";
          latitude = config.modules.homeAssistant.latitude;
          longitude = config.modules.homeAssistant.longitude;
          elevation = 0;
          unit_system = config.modules.homeAssistant.unitSystem;
          time_zone = config.modules.homeAssistant.timeZone;
        };
        
        # Basic components
        http = {};
        frontend = {};
        config = {};
        recorder = {};
        history = {};
        
        # TP-Link Kasa integration
        tplink = mkIf config.modules.homeAssistant.tplink.enable {
          discovery = config.modules.homeAssistant.tplink.discoveryEnabled;
          switch = map (name: {
            host = config.modules.homeAssistant.tplink.devices.${name};
            name = name;
          }) (builtins.attrNames config.modules.homeAssistant.tplink.devices);
        };
        
        # Reolink Camera configuration
        camera = mkIf config.modules.homeAssistant.reolink.enable (
          builtins.listToAttrs (map 
            (name: {
              name = "platform";
              value = {
                platform = "reolink";
                host = config.modules.homeAssistant.reolink.cameras.${name}.host;
                port = config.modules.homeAssistant.reolink.cameras.${name}.port;
                username = config.modules.homeAssistant.reolink.cameras.${name}.username;
                password = config.modules.homeAssistant.reolink.cameras.${name}.password;
                channel = config.modules.homeAssistant.reolink.cameras.${name}.channel;
                stream = config.modules.homeAssistant.reolink.cameras.${name}.stream;
                name = name;
              };
            }) 
            (builtins.attrNames config.modules.homeAssistant.reolink.cameras)
          )
        );
        
        # Add any extra components defined in the module options
      } // builtins.listToAttrs (map (comp: { name = comp; value = {}; }) 
                                   config.modules.homeAssistant.extraComponents);
      
      extraPackages = py: with py; [
        # Base packages for Reolink integration
        aiohttp
        urllib3
        
        # Additional packages for Reolink if using HACS integration
        async-timeout
        
        # Include user-defined packages
      ] ++ config.modules.homeAssistant.extraPackages py;
    };
    
    # Enable HACS (Home Assistant Community Store) for better Reolink support
    systemd.services.hacs-installer = {
      enable = true;
      description = "HACS Installer for Home Assistant";
      after = [ "home-assistant.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "hass";
        ExecStart = pkgs.writeShellScript "install-hacs" ''
          HASS_CONFIG="${config.modules.homeAssistant.configDir}"
          HACS_DIR="$HASS_CONFIG/custom_components/hacs"
          
          if [ ! -d "$HACS_DIR" ]; then
            mkdir -p "$HACS_DIR"
            cd "$(mktemp -d)"
            ${pkgs.curl}/bin/curl -sfSL https://github.com/hacs/integration/releases/latest/download/hacs.zip -o hacs.zip
            ${pkgs.unzip}/bin/unzip hacs.zip -d ./hacs
            cp -r ./hacs/* "$HACS_DIR/"
            echo "HACS has been installed. Please restart Home Assistant."
          fi
        '';
      };
    };
    
    # Optional: add udev rules for common smart home hardware
    services.udev.extraRules = ''
      # Z-Wave stick
      SUBSYSTEM=="tty", ATTRS{idVendor}=="0658", ATTRS{idProduct}=="0200", SYMLINK+="zwave", GROUP="dialout"
      
      # Conbee/Deconz Zigbee stick
      SUBSYSTEM=="tty", ATTRS{idVendor}=="1cf1", ATTRS{idProduct}=="0030", SYMLINK+="zigbee", GROUP="dialout"
    '';
    
    users.users.hass.extraGroups = [ "dialout" ];
  };
}

