# modules/home-manager/bitwarden-cli.nix
{ config, pkgs, lib, inputs, ... }:
let
  cfg = config.programs.bitwarden-cli;
in
{
  options.programs.bitwarden-cli = {
    enable = lib.mkEnableOption "Bitwarden CLI";
    
    sessionSecretPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to the BW_SESSION secret file";
      example = "\${config.sops.secrets.BW_SESSION.path}";
    };

    autoDetectSopsSecret = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically use sops BW_SESSION secret if available";
    };
  };

  config = lib.mkIf cfg.enable (let
    # Auto-detect sops secret path if enabled and available
    secretPath = 
      if cfg.sessionSecretPath != null then
        cfg.sessionSecretPath
      else if cfg.autoDetectSopsSecret && (config.sops.secrets ? BW_SESSION) then
        config.sops.secrets.BW_SESSION.path
      else
        null;
  in {
    home.packages = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
      bitwarden-cli
    ]);

    # Configure BW_SESSION environment variable for all shells
    programs.bash.initExtra = lib.mkIf (secretPath != null) ''
      if [[ -f "${secretPath}" ]]; then
        export BW_SESSION="$(cat ${secretPath})"
      fi
    '';

    programs.zsh.initExtra = lib.mkIf (secretPath != null) ''
      if [[ -f "${secretPath}" ]]; then
        export BW_SESSION="$(cat ${secretPath})"
      fi
    '';

    programs.fish.interactiveShellInit = lib.mkIf (secretPath != null) ''
      if test -f ${secretPath}
        set -gx BW_SESSION (cat ${secretPath})
      end
    '';

    programs.nushell.extraConfig = lib.mkIf (secretPath != null) ''
      if (${secretPath} | path exists) {
        $env.BW_SESSION = (open ${secretPath} | str trim)
      }
    '';
  });
}
