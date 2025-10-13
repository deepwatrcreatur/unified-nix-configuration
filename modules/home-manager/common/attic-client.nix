{ config, lib, pkgs, ... }:

let
  cfg = config.services.attic-client;
in
{
  options.services.attic-client = {
    enable = lib.mkEnableOption "Attic binary cache client" // {
      default = true;
      description = "Whether to enable Attic binary cache client with SOPS-managed authentication";
    };

    servers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          endpoint = lib.mkOption {
            type = lib.types.str;
            description = "Attic server endpoint URL";
          };
          tokenPath = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/.config/sops/attic-client-token";
            description = "Path to the SOPS-decrypted token file";
          };
        };
      });
      default = {};
      description = "Attic servers configuration";
    };

    defaultServers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          endpoint = lib.mkOption {
            type = lib.types.str;
            description = "Attic server endpoint URL";
          };
          tokenPath = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/.config/sops/attic-client-token";
            description = "Path to the SOPS-decrypted token file";
          };
        };
      });
      default = {
        cache-build-server = {
          endpoint = "http://cache-build-server:5001";
        };
        cache-build-server-local = {
          endpoint = "http://localhost:5001";
        };
      };
      description = "Default Attic servers (can be overridden)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install attic-client
    home.packages = [ pkgs.attic-client ];

    # Merge default servers with user-specified servers
    services.attic-client.servers = lib.mkDefault cfg.defaultServers;

    # Home activation script to substitute tokens
    home.activation.attic-config = lib.hm.dag.entryAfter ["linkGeneration"] ''
      config_dir="${config.home.homeDirectory}/.config/attic"
      config_file="$config_dir/config.toml"

      # Only run if we're the actual user, not root during system activation
      if [[ "$HOME" == "${config.home.homeDirectory}" ]]; then
        mkdir -p "$config_dir"

        # Generate the config template inline
        cat > "$config_file" <<'ATTIC_EOF'
${let
  allServers = cfg.defaultServers // cfg.servers;
  serverConfigs = lib.mapAttrsToList (name: server: ''
[servers.${name}]
endpoint = "${server.endpoint}"
token = "@ATTIC_CLIENT_TOKEN_${lib.toUpper (builtins.replaceStrings ["-"] ["_"] name)}@"
  '') allServers;
in lib.concatStringsSep "\n" serverConfigs}
ATTIC_EOF

        # Make it writable (should already be, but just in case)
        chmod u+w "$config_file"

            ${lib.concatStringsSep "\n            " (lib.mapAttrsToList (name: server: ''
              # Substitute token for ${name}
              if [[ -f "${server.tokenPath}" ]]; then
                token=$(cat "${server.tokenPath}" 2>/dev/null || echo "")
                if [[ -n "$token" ]]; then
                  placeholder="@ATTIC_CLIENT_TOKEN_${lib.toUpper (builtins.replaceStrings ["-"] ["_"] name)}@"
                  sed -i'.bak' "s|$placeholder|$token|g" "$config_file"
                  rm -f "$config_file.bak"
                else
                  echo "Warning: Token file empty for ${name}: ${server.tokenPath}" >&2
                fi
              else
                echo "Warning: Token file not found for ${name}: ${server.tokenPath}" >&2
              fi
            '') (cfg.defaultServers // cfg.servers))}

        echo "Attic client configuration with tokens saved to $config_file"
      else
        echo "Skipping attic-client config setup - not running as user ${config.home.username}" >&2
      fi
    '';

    # Set ATTIC_CONFIG environment variable (optional, attic uses ~/.config/attic/config.toml by default)
    home.sessionVariables = {
      ATTIC_CONFIG = "${config.home.homeDirectory}/.config/attic/config.toml";
    };

    # Add shell aliases for convenience
    home.shellAliases = {
      attic-push-local = "attic push cache-local";
      attic-push-build-server = "attic push cache-build-server";
    };
  };
}