

{ config, lib, pkgs, ... }:

let
  cfg = config.programs.attic-client;

  # The content of the post-build hook script
  uploadScriptContent = pkgs.writeShellScript "attic-upload.sh" ''
    #!"${pkgs.bash}/bin/bash
    # This script is executed by the post-build-hook.
    # It pushes the paths of newly built derivations to the Attic cache.

    set -euo pipefail

    # The paths to upload are passed as arguments.
    PATHS_TO_UPLOAD="$@"

    if [ -z "$PATHS_TO_UPLOAD" ]; then
      # No paths to upload, exit gracefully.
      exit 0
    fi

    echo "Attic: Pushing paths to cache..."
    # Use the user's configured attic client
    ${pkgs.attic-client}/bin/attic push cache-local $PATHS_TO_UPLOAD
    echo "Attic: Push complete."
  '';
in
{
  options.programs.attic-client = {
    enable = lib.mkEnableOption "Attic binary cache client (Home Manager)" // {
      default = false;
      description = "Whether to enable the Attic client at the user level.";
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
    # 1. Install the package
    home.packages = [ pkgs.attic-client ];

    # 2. Place the upload script in the user's home
    home.file.".config/attic/upload.sh" = {
      source = uploadScriptContent;
      executable = true;
    };

    # 3. Configure nix.conf to use the hook
    nix.extraOptions = ''
      post-build-hook = ${config.home.homeDirectory}/.config/attic/upload.sh
    '';

    # 4. Create Attic client configuration template
    home.file.".config/attic/config.toml".text =
      let
        allServers = cfg.defaultServers // cfg.servers;
        serverConfigs = lib.mapAttrsToList (name: server: ''
          [servers.${name}]
          endpoint = "${server.endpoint}"
          token = "@ATTIC_CLIENT_TOKEN_${lib.toUpper (builtins.replaceStrings ["-"] ["_"] name)}@"
        '') allServers;
      in
      lib.concatStringsSep "\n\n" serverConfigs;

    # 5. Home activation script to substitute tokens
    home.activation.attic-config = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/attic

      if [[ -f ${config.home.homeDirectory}/.config/attic/config.toml ]]; then
        config_file="${config.home.homeDirectory}/.config/attic/config.toml"
        temp_file="/tmp/attic-config-$$.toml"

        # Copy the template
        cp "$config_file" "$temp_file"

        ${lib.concatStringsSep "\n        " (lib.mapAttrsToList (name: server: ''
          # Substitute token for ${name}
          if [[ -f "${server.tokenPath}" ]]; then
            token=$(cat "${server.tokenPath}")
            placeholder="@ATTIC_CLIENT_TOKEN_${lib.toUpper (builtins.replaceStrings ["-"] ["_"] name)}@"
            $DRY_RUN_CMD sed -i "s|$placeholder|$token|g" "$temp_file"
          else
            $VERBOSE_ECHO "Warning: Token file not found for ${name}: ${server.tokenPath}"
          fi
        '') (cfg.defaultServers // cfg.servers))}

        # Move the configured file into place
        $DRY_RUN_CMD mv "$temp_file" "$config_file"
        $VERBOSE_ECHO "Attic client configuration updated with SOPS tokens"
      fi
    '';
  };
}
