{ config, lib, pkgs, ... }:

let
  cfg = config.programs.herdr;

  herdrPreflight = pkgs.writeShellScriptBin "herdr-preflight" ''
    set -euo pipefail

    target="''${1:-.}"

    if ! git_root="$(${pkgs.git}/bin/git -C "$target" rev-parse --show-toplevel 2>/dev/null)"; then
      if [ "$(${pkgs.git}/bin/git -C "$target" rev-parse --is-bare-repository 2>/dev/null)" = "true" ]; then
        echo "❌ herdr-preflight: BLOCKED. Current directory is a BARE repository."
        echo "Agents must not mutate files directly in bare checkouts."
        echo "Create a linked worktree instead:"
        echo "  git -C \"$target\" worktree add ~/flakes-worktrees/<repo>/<branch> -b <branch>"
        exit 1
      fi
      echo "ℹ️  herdr-preflight: not inside a git repository."
      exit 0
    fi

    if [ -f "$git_root/.git" ]; then
      echo "✅ herdr-preflight: ALLOWED (linked git worktree detected at $git_root)."
      if command -v btrfs >/dev/null 2>&1 && btrfs subvolume show "$git_root" >/dev/null 2>&1; then
        echo "   [btrfs subvolume detected: isolated from parent snapper snapshots]"
      fi
      exit 0
    elif [ -d "$git_root/.git" ]; then
      echo "⚠️  herdr-preflight: WARNING: Primary repository checkout detected at $git_root."
      echo "To avoid colliding with other agents or operator work, consider creating a linked worktree:"
      echo "  git -C \"$git_root\" worktree add ~/flakes-worktrees/<repo>/<branch> -b <branch>"
      exit 0
    fi
  '';
in
{
  options.programs.herdr = {
    enable = lib.mkEnableOption "herdr - a terminal-native agent multiplexer";
    desktopApp.enable = lib.mkEnableOption "the herdr desktop app (herdr-app)";
    core.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.desktopApp.enable;
      defaultText = lib.literalExpression "config.programs.herdr.desktopApp.enable";
      description = ''
        Install herdr-core (`hc`), the runtime behind herdr-app. The herdr
        iPhone/iPad/Android apps connect to it over SSH (`hc connect`); they do
        not work with the herdr TUI.
      '';
    };
    core.autostart = lib.mkOption {
      type = lib.types.bool;
      default = cfg.core.enable;
      defaultText = lib.literalExpression "config.programs.herdr.core.enable";
      description = ''
        Start herdr-core when the systemd user manager starts. Pair with
        `users.users.<name>.linger = true` on NixOS so that happens at boot,
        making kept terminals come back without waiting for a client.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable { home.packages = [ pkgs.herdr herdrPreflight ]; })
    (lib.mkIf cfg.desktopApp.enable { home.packages = [ pkgs.herdr-app ]; })
    (lib.mkIf cfg.core.enable { home.packages = [ pkgs.herdr-core ]; })
    (lib.mkIf (cfg.core.enable && cfg.core.autostart) {
      # `hc server start` launches the core as its own transient user unit
      # (systemd-run) and returns, so this unit is a oneshot trigger.
      systemd.user.services.herdr-core = {
        Unit = {
          Description = "Start herdr-core (hc)";
          After = [ "basic.target" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.herdr-core}/bin/hc server start";
        };
        Install.WantedBy = [ "default.target" ];
      };
    })
  ];
}
