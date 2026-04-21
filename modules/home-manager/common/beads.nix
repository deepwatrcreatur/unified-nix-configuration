# modules/home-manager/common/beads.nix
# Beads coordination stack: beads-rust (repo-managed wrapper around upstream br)
# + bv (beads_viewer)
#
# beads-rust — CLI for creating, updating, and querying the .beads/ task store
# bv  — TUI + robot-triage engine; reads PageRank/critical-path from store
#
# Usage after `home-manager switch`:
#   beads-rust init        — initialise .beads/ in a repo
#   beads-rust ready --json — list unblocked tasks as JSON
#   bv                  — open interactive terminal UI
#   bv --robot-triage --labels tooling --json   — agent-friendly priority list
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.beads;
in
{
  options.programs.beads = {
    enable = lib.mkEnableOption "Beads coordination stack (beads-rust + bv)";

    enableBr = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the repo-managed beads-rust CLI wrapper.";
    };

    enableBv = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install bv (beads_viewer) TUI and robot-triage CLI.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      lib.optional cfg.enableBr pkgs.beads-rust-cli
      ++ lib.optional cfg.enableBv pkgs.beads-viewer;
  };
}
