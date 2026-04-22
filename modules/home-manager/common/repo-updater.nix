# modules/home-manager/common/repo-updater.nix
# repo_updater (ru) — fleet-wide multi-repo sync and review
#
# Installs `ru` and writes ~/.config/ru/config to point at ~/flakes/
# as the workspace root.  The per-user repos list lives in
# ~/.config/ru/repos.d/ and is NOT managed here so users can maintain
# their own lists without NixOS rebuild cycles.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.repo-updater;
in
{
  options.programs.repo-updater = {
    enable = lib.mkEnableOption "repo_updater (ru) fleet sync tool";

    projectsDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/flakes";
      description = ''
        Root directory where `ru sync` clones and updates repositories.
        Corresponds to RU's PROJECTS_DIR setting.
      '';
    };

    layout = lib.mkOption {
      type = lib.types.enum [
        "flat"
        "owner-repo"
        "full"
      ];
      default = "flat";
      description = ''
        Directory layout strategy for cloned repos.
        `flat` places repos directly under projectsDir (matching the
        existing ~/flakes/ convention).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.repo-updater ];

    # Write the ru config file.
    # ru reads ~/.config/ru/config (shell-style KEY=VALUE).
    xdg.configFile."ru/config".text = ''
      PROJECTS_DIR="${cfg.projectsDir}"
      LAYOUT="${cfg.layout}"
    '';

    # Ensure the repos.d directory exists so `ru init` is not required.
    # The actual repos lists are user-managed (not NixOS-managed).
    home.activation.ruReposDirInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "${config.xdg.configHome}/ru/repos.d"
    '';
  };
}
