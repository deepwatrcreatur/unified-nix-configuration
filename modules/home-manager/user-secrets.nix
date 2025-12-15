{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.user-secrets;
in
{
  options.services.user-secrets = {
    enable = mkEnableOption "User-specific SOPS secrets activation";

    secretsPath = mkOption {
      type = types.path;
      description = "Path to the user secrets directory";
    };
  };

  config = mkIf cfg.enable {
    home.activation.userSecretsActivation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
      export PATH="${lib.makeBinPath [ pkgs.sops ]}:$PATH"

      # Decrypt attic-client-token
      mkdir -p "$HOME/.config/sops"
      sops -d "${toString cfg.secretsPath}/attic-client-token.yaml.enc" > "$HOME/.config/sops/attic-client-token"
      chmod 600 "$HOME/.config/sops/attic-client-token"
    '';
  };
}