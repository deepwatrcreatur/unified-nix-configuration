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
    # Install attic-client and sops for token decryption
    home.packages = [ pkgs.attic-client pkgs.sops ];

    # Merge default servers with user-specified servers
    services.attic-client.servers = lib.mkDefault cfg.defaultServers;

    # Set SOPS environment variable for token decryption
    home.sessionVariables = {
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    };

    # Home activation script to decrypt token and substitute into config
    home.activation.attic-config = lib.hm.dag.entryAfter ["linkGeneration"] ''
      config_dir="${config.home.homeDirectory}/.config/attic"
      config_file="$config_dir/config.toml"
      token_file="${config.home.homeDirectory}/.config/sops/attic-client-token"

      # Only run if we're the actual user, not root during system activation
      if [[ "$HOME" == "${config.home.homeDirectory}" ]]; then
        # Ensure sops config directory exists
        mkdir -p "${config.home.homeDirectory}/.config/sops"
        mkdir -p "$config_dir"

        # Decrypt Attic client token from global secrets if not already decrypted
        global_token_path="${config.home.homeDirectory}/unified-nix-configuration/secrets/attic-client-token.yaml.enc"

        if [[ ! -f "$token_file" ]] || [[ "$global_token_path" -nt "$token_file" ]]; then
          if [[ -f "$global_token_path" ]]; then
            echo "Decrypting Attic client token from global secrets..." >&2

            # Export SOPS_AGE_KEY_FILE and add sops to PATH
            export SOPS_AGE_KEY_FILE="${config.home.homeDirectory}/.config/sops/age/keys.txt"
            export PATH="${lib.makeBinPath [ pkgs.sops ]}:$PATH"

            if SOPS_OUTPUT=$(sops --input-type yaml --output-type yaml -d "$global_token_path" 2>&1 | grep "ATTIC_CLIENT_JWT_TOKEN:" | cut -d: -f2- | xargs); then
              echo "$SOPS_OUTPUT" > "$token_file"
              chmod 600 "$token_file"
              echo "Attic client token decrypted successfully" >&2
            else
              echo "Warning: Failed to decrypt Attic client token" >&2
              echo "Debug: SOPS error output: $SOPS_OUTPUT" >&2
              # Continue anyway - token might already exist
            fi
          else
            echo "Warning: Attic client token not found at $global_token_path" >&2
          fi
        fi

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
              token=""
              if [[ -f "${server.tokenPath}" ]]; then
                token=$(cat "${server.tokenPath}" 2>/dev/null || echo "")
              elif [[ -f "${config.home.homeDirectory}/.config/sops/attic-client-token" ]]; then
                # Read token from secrets-activation decrypted file
                token=$(cat "${config.home.homeDirectory}/.config/sops/attic-client-token" 2>/dev/null || echo "")
              fi

              if [[ -n "$token" ]]; then
                placeholder="@ATTIC_CLIENT_TOKEN_${lib.toUpper (builtins.replaceStrings ["-"] ["_"] name)}@"
                sed -i'.bak' "s|$placeholder|$token|g" "$config_file"
                rm -f "$config_file.bak"
                echo "Successfully applied attic token for ${name}" >&2
              else
                echo "Warning: Token not found for ${name}" >&2
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
      attic-push = "attic push cache-build-server:cache-local";
      attic-push-cache-local = "attic push cache-build-server:cache-local";
    };
  };
}