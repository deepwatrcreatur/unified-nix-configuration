{ config, pkgs, lib, ... }:

let
  cfg = config.programs.atuin;
in
{
  options.programs.atuin = {
    enable = lib.mkEnableOption "Atuin, a modern shell history replacement.";

    package = lib.mkPackageOption pkgs "atuin" {
      description = "The Atuin package to use.";
    };

    # extraConfig = lib.mkOption {
    #   type = lib.types.lines;
    #   default = "";
    #   description = "Additional lines for Atuin config file.";
    # };
  };

  config = lib.mkIf cfg.enable {
    # Ensure the Atuin package is available
    home.packages = [ cfg.package ];

    # Configure the shell to use Atuin
    programs.bash = {
      enable = true;
      initExtra = ''
        eval "$(${cfg.package}/bin/atuin init bash)"
      '';
    };

    programs.zsh = {
      enable = true;
      initExtra = ''
        eval "$(${cfg.package}/bin/atuin init zsh)"
      '';
    };

    programs.fish = {
      enable = true;
      initExtra = ''
        atuin init fish | source
      '';
    };

    programs.nushell = {
      enable = true;
      extraConfig = ''
        atuin init nu | source
      '';
    };

    # xdg.configFile."atuin/config.toml".source =
    #   lib.mkIf (cfg.sync) (pkgs.writeText "atuin-config.toml" ''
    #     sync_frequency = "10m"
    #     auto_sync = true
    #     ${cfg.extraConfig}
    #   '');
  };
}
