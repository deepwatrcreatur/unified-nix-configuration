# modules/home-manager/common/worktrunk.nix
# Worktrunk (wt) - Git worktree manager optimized for parallel agent workflows
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.worktrunk;
in
{
  options.programs.worktrunk = {
    enable = lib.mkEnableOption "worktrunk (wt) Git worktree manager";

    package = lib.mkPackageOption pkgs "worktrunk" { };

    enableFishIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Fish shell integration for worktrunk";
    };

    enableBashIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Bash shell integration for worktrunk";
    };

    enableZshIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Zsh shell integration for worktrunk";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration (lib.mkAfter ''
      if type -q wt
        wt config shell init fish | source
      end
    '');

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration (lib.mkAfter ''
      if command -v wt >/dev/null 2>&1; then
        eval "$(wt config shell init bash)"
      fi
    '');

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration (lib.mkAfter ''
      if command -v wt >/dev/null 2>&1; then
        eval "$(wt config shell init zsh)"
      fi
    '');
  };
}
