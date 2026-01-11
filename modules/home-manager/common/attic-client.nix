{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.programs.attic-client;
in
{
  options.programs.attic-client = {
    enable = lib.mkEnableOption "Attic binary cache client" // {
      default = false;
      description = "Whether to enable Attic binary cache client with SOPS-managed authentication";
    };

    servers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
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
        }
      );
      default = { };
      description = "Attic servers configuration";
    };

    defaultServers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
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
        }
      );
      default = {
        cache-build-server = {
          endpoint = "http://cache-build-server:5001";
        };
        cache-build-server-local = {
          endpoint = "http://cache-build-server:5001";
        };
      };
      description = "Default Attic servers (can be overridden)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install attic-client
    home.packages = [ pkgs.attic-client ];

    # Merge default servers with user-specified servers
    programs.attic-client.servers = lib.mkDefault cfg.defaultServers;

    # Create Attic client configuration template
    home.file.".config/attic/config.toml".text =
      let
        allServers = cfg.defaultServers // cfg.servers;
        serverConfigs = lib.mapAttrsToList (name: server: ''
          [servers.${name}]
          endpoint = "${server.endpoint}"
          token = "@ATTIC_CLIENT_TOKEN_${lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] name)}@"
        '') allServers;
      in
      lib.concatStringsSep "\n\n" serverConfigs;

    # Home activation script to substitute tokens
    home.activation.attic-config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/attic

      # Ensure fnox is available
      export PATH="${pkgs.fnox}/bin:$PATH"
        export FNOX_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"

        if [[ -f ${config.home.homeDirectory}/.config/attic/config.toml ]]; then
          config_file="${config.home.homeDirectory}/.config/attic/config.toml"
          temp_file="/tmp/attic-config-$$.toml"

          # Copy the template
          cp "$config_file" "$temp_file"

          # Try to get token from fnox
          fnox_token=$(fnox get ATTIC_CLIENT_JWT_TOKEN 2>/dev/null || echo "")

          ${lib.concatStringsSep "\n        " (
            lib.mapAttrsToList (name: server: ''
              # Substitute token for ${name}
              placeholder="@ATTIC_CLIENT_TOKEN_${lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] name)}@"

              if [[ -n "$fnox_token" ]]; then
                 $DRY_RUN_CMD sed -i "s|$placeholder|$fnox_token|g" "$temp_file"
              elif [[ -f "${server.tokenPath}" ]]; then
                token=$(cat "${server.tokenPath}")
                $DRY_RUN_CMD sed -i "s|$placeholder|$token|g" "$temp_file"
              else
                $VERBOSE_ECHO "Warning: Token not found in fnox or file for ${name}: ${server.tokenPath}"
              fi
            '') (cfg.defaultServers // cfg.servers)
          )}

          # Move the configured file into place
          $DRY_RUN_CMD mv "$temp_file" "$config_file"
          $VERBOSE_ECHO "Attic client configuration updated with tokens"
        fi
    '';

    # Add shell aliases for convenience
    home.shellAliases = {
      attic-push-local = "attic push cache-local";
      attic-push-build-server = "attic push cache-build-server";
    };
  };
}
