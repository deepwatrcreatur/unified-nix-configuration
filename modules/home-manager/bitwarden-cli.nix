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
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
      bitwarden-cli
    ]);

    # Configure BW_SESSION environment variable for all shells
    programs.bash.initExtra = lib.mkIf (cfg.sessionSecretPath != null) ''
      export BW_SESSION="$(cat ${cfg.sessionSecretPath})"
    '';

    programs.zsh.initExtra = lib.mkIf (cfg.sessionSecretPath != null) ''
      export BW_SESSION="$(cat ${cfg.sessionSecretPath})"
    '';

    programs.fish.interactiveShellInit = lib.mkIf (cfg.sessionSecretPath != null) ''
      set -gx BW_SESSION (cat ${cfg.sessionSecretPath})
    '';

    programs.nushell.extraConfig = lib.mkIf (cfg.sessionSecretPath != null) ''
      $env.BW_SESSION = (open ${cfg.sessionSecretPath} | str trim)
    '';
  };
}
