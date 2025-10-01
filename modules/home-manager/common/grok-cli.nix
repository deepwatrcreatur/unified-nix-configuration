{ config, lib, pkgs, ... }:

let
  cfg = config.programs.grok-cli;
  globalSopsSecretsDir = toString (builtins.path { path = ../../../secrets; });
in
{
  options.programs.grok-cli = {
    enable = lib.mkEnableOption "Grok CLI with XAI API key integration" // {
      default = true;
      description = "Whether to enable grok-cli with automatic API key injection for all shells.";
    };

    apiKeyPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/sops/grok-api-key";
      description = "Path to the SOPS-decrypted XAI API key file";
    };

    manageSopsSecret = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether this module should manage the SOPS secret configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install grok-cli package
    home.packages = [ pkgs.grok-cli ];

    # Configure SOPS secret for XAI API key (only if manageSopsSecret is true)
    sops.secrets."xai-api-key" = lib.mkIf cfg.manageSopsSecret {
      sopsFile = "${globalSopsSecretsDir}/xai_api_key.enc";
      format = "binary";
      path = cfg.apiKeyPath;
      mode = "0600";
    };

    # Set environment variable for all shells through sessionVariables
    home.sessionVariables = {
      GROK_API_KEY = "$(cat ${cfg.apiKeyPath} 2>/dev/null || echo '')";
    };

    # Fish shell configuration
    programs.fish = {
      shellInit = ''
        # Load Grok API key
        if test -f ${cfg.apiKeyPath}
          set -gx GROK_API_KEY (cat ${cfg.apiKeyPath})
        end
      '';
    };

    # Bash shell configuration
    programs.bash = {
      initExtra = ''
        # Load Grok API key
        if [[ -f "${cfg.apiKeyPath}" ]]; then
          export GROK_API_KEY="$(cat ${cfg.apiKeyPath})"
        fi
      '';
    };

    # Zsh shell configuration
    programs.zsh = {
      initExtra = ''
        # Load Grok API key
        if [[ -f "${cfg.apiKeyPath}" ]]; then
          export GROK_API_KEY="$(cat ${cfg.apiKeyPath})"
        fi
      '';
    };

    # Nushell configuration
    programs.nushell = {
      extraConfig = ''
        # Load Grok API key
        let grok_key_file = "${cfg.apiKeyPath}"
        if ($grok_key_file | path exists) {
          $env.GROK_API_KEY = (open $grok_key_file | str trim)
        }
      '';
    };
  };
}
