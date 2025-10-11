

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

    # 4. Create Attic client configuration template (as a writable file, not symlink)
    home.file.".config/attic/config.toml.template".text =
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

      template_file="${config.home.homeDirectory}/.config/attic/config.toml.template"
      config_file="${config.home.homeDirectory}/.config/attic/config.toml"

      if [[ -f "$template_file" ]]; then
        # Copy the template
        cp "$template_file" "$config_file"

        ${lib.concatStringsSep "\n        " (lib.mapAttrsToList (name: server: ''
          # Substitute token for ${name}
          if [[ -f "${server.tokenPath}" ]]; then
            # Read token and extract value if in shell export format
            token_line=$(cat "${server.tokenPath}")
            # Extract value between quotes if present (shell export format), otherwise use as-is
            if [[ "$token_line" =~ =\"(.*)\" ]]; then
              token="''${BASH_REMATCH[1]}"
            else
              token="$token_line"
            fi

            placeholder="@ATTIC_CLIENT_TOKEN_${lib.toUpper (builtins.replaceStrings ["-"] ["_"] name)}@"
            # Use portable sed syntax (create temp file)
            $DRY_RUN_CMD ${pkgs.gnused}/bin/sed "s|$placeholder|$token|g" "$config_file" > "$config_file.tmp"
            $DRY_RUN_CMD mv "$config_file.tmp" "$config_file"
          else
            $VERBOSE_ECHO "Warning: Token file not found for ${name}: ${server.tokenPath}"
          fi
        '') (cfg.defaultServers // cfg.servers))}

        $VERBOSE_ECHO "Attic client configuration updated with SOPS tokens"
      fi
    '';
  };
}
