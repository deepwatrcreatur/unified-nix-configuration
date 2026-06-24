{ config, lib, pkgs, ... }:

let
  cfg = config.programs.jj;
in
{
  options.programs.jj = {
    enable = lib.mkEnableOption "Jujutsu and related terminal tooling";

    enableJjui = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install jjui alongside jujutsu.";
    };

    enableStarshipIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to render repository state via jj-starship when Starship is enabled.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      programs.jujutsu = {
        enable = true;
        package = pkgs.jujutsu;
      };

      home.packages =
        [ ]
        ++ lib.optional cfg.enableJjui pkgs.jjui
        ++ lib.optional (cfg.enableStarshipIntegration && config.programs.starship.enable) pkgs.jj-starship;
    }

    (lib.mkIf (cfg.enableStarshipIntegration && config.programs.starship.enable) {
      programs.starship.settings = {
        git_branch.disabled = lib.mkForce true;
        git_status.disabled = lib.mkForce true;
        custom.jj = {
          when = "${lib.getExe pkgs.jj-starship} detect";
          command = "";
          shell = [ "${lib.getExe pkgs.jj-starship}" ];
          format = "$output ";
          ignore_timeout = true;
        };
      };
    })
  ]);
}
