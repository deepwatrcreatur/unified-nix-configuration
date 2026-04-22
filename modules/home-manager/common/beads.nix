# modules/home-manager/common/beads.nix
# Beads coordination stack: br (beads_rust) + bv (beads_viewer)
#
# br  — CLI for creating, updating, and querying the .beads/ task store
# bv  — TUI + robot-triage engine; reads PageRank/critical-path from store
#
# Usage after `home-manager switch`:
#   br init             — initialise .beads/ in a repo
#   br ready --json     — list unblocked tasks as JSON
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
    enable = lib.mkEnableOption "Beads coordination stack (br + bv)";

    enableBr = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install br (beads_rust) CLI.";
    };

    enableBv = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install bv (beads_viewer) TUI and robot-triage CLI.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      lib.optional cfg.enableBr pkgs.beads-rust
      ++ lib.optional cfg.enableBv pkgs.beads-viewer;
  };
}
