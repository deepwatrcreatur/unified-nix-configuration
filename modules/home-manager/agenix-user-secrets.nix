{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.agenix-user-secrets;
  secretType = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.path;
        description = "Encrypted age file to decrypt for this user.";
      };

      target = lib.mkOption {
        type = lib.types.str;
        description = "Path relative to the home directory where the decrypted secret is written.";
      };

      extraTargets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional home-relative paths where the decrypted secret should also be installed.";
      };

      mode = lib.mkOption {
        type = lib.types.str;
        default = "0600";
        description = "File mode applied to the decrypted secret.";
      };
    };
  };
in
{
  options.services.agenix-user-secrets = {
    enable = lib.mkEnableOption "User-scoped agenix secret decryption";

    identityFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.ssh/id_ed25519";
      description = "Private key used to decrypt user-scoped age secrets.";
    };

    secrets = lib.mkOption {
      type = lib.types.attrsOf secretType;
      default = { };
      description = "User secrets to decrypt during Home Manager activation.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.agenixUserSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      if [ ! -f "${cfg.identityFile}" ]; then
        echo "Warning: agenix-user-secrets identity not found at ${cfg.identityFile}"
        exit 0
      fi

      tmp_dir="$(mktemp -d)"
      trap 'rm -rf "$tmp_dir"' EXIT

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: secret:
          let
            targetPath = "${config.home.homeDirectory}/${secret.target}";
            installTargets = [ targetPath ] ++ map (target: "${config.home.homeDirectory}/${target}") secret.extraTargets;
            mkdirCommands = lib.concatStringsSep "\n" (
              map (path: ''mkdir -p "${builtins.dirOf path}"'') installTargets
            );
            installCommands = lib.concatStringsSep "\n" (
              map (path: ''install -m ${secret.mode} "$tmp_dir/${name}" "${path}"'') installTargets
            );
          in
          ''
            ${mkdirCommands}
            ${pkgs.rage}/bin/rage -d -i "${cfg.identityFile}" -o "$tmp_dir/${name}" "${secret.source}"
            ${installCommands}
          ''
        ) cfg.secrets
      )}
    '';
  };
}
