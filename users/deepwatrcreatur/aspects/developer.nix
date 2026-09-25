# users/deepwatrcreatur/aspects/developer.nix
# Reusable Home Manager developer persona aspect:
# Shell environment, dev CLI utilities, Git/SSH tools, and repository workflows.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  unifiedMainWorktree = "/home/deepwatrcreatur/flakes-worktrees/unified-nix-configuration/main";
in
{
  imports = [
    ../default.nix
    ../../../modules/nh.nix
    ../hosts/workstation/distrobox.nix
    ../../../modules/home-manager/agenix-user-secrets.nix
    ../../../modules/home-manager/ghostty
    ../../../modules/home-manager/git-ssh-signing.nix
    ../../../modules/home-manager/ssh-agent.nix
    ../../../modules/home-manager/zed.nix
    ../../../modules/home-manager/common/dmux.nix
    ../../../modules/home-manager/hunk.nix
  ];

  programs.nh = {
    flake = unifiedMainWorktree;
  };

  programs.hunk-custom.enable = true;
  programs.t3code.enable = true;
  programs.cmux-tui.enable = true;
  programs.dmux.enable = true;
  programs.herdr.enable = true;
  programs.jj.enable = true;
  programs.qmd.enable = true;
  programs.repo-updater.enable = true;
  programs.beads.enable = true;
  programs.beads.enableBv = false;

  programs.rtk-hooks.integrations = {
    claude.enable = true;
    codex.enable = true;
    gemini.enable = true;
    opencode.enable = true;
  };

  services.agenix-user-secrets = {
    enable = true;
    secrets = {
      github-token = {
        source = ../../../secrets-agenix/github-token.age;
        target = ".local/share/agenix-user-secrets/github-token";
        extraTargets = [ ".config/git/github-token" ];
      };
      grok-api-key = {
        source = ../../../secrets-agenix/grok-api-key.age;
        target = ".local/share/agenix-user-secrets/grok-api-key";
      };
      openrouter-api-key = {
        source = ../../../secrets-agenix/openrouter-api-key.age;
        target = ".local/share/agenix-user-secrets/openrouter-api-key";
      };
      z-ai-api-key = {
        source = ../../../secrets-agenix/z-ai-api-key.age;
        target = ".local/share/agenix-user-secrets/z-ai-api-key";
      };
      opencode-zen-api-key = {
        source = ../../../secrets-agenix/opencode-zen-api-key.age;
        target = ".local/share/agenix-user-secrets/opencode-zen-api-key";
      };
      openai-api-key = {
        source = ../../../secrets-agenix/openai-api-key.age;
        target = ".local/share/agenix-user-secrets/openai-api-key";
      };
      gemini-api-key = {
        source = ../../../secrets-agenix/gemini-api-key.age;
        target = ".local/share/agenix-user-secrets/gemini-api-key";
      };
      atuin-key-b64 = {
        source = ../../../secrets-agenix/atuin-key-b64.age;
        target = ".local/share/agenix-user-secrets/atuin-key-b64";
      };
      anthropic-api-key = {
        source = ../../../secrets-agenix/anthropic-api-key.age;
        target = ".local/share/agenix-user-secrets/anthropic-api-key";
      };
      deepseek-api-key = {
        source = ../../../secrets-agenix/deepseek-api-key.age;
        target = ".local/share/agenix-user-secrets/deepseek-api-key";
      };
      oauth-creds = {
        source = ../../../secrets-agenix/oauth-creds.age;
        target = ".local/share/agenix-user-secrets/oauth-creds";
        extraTargets = [ ".gemini/oauth_creds.json" ];
      };
      bitwarden-data = {
        source = ../../../secrets-agenix/bitwarden-data.age;
        target = ".local/share/agenix-user-secrets/bitwarden-data";
        extraTargets = [ ".config/Bitwarden CLI/data.json" ];
      };
      rclone-conf = {
        source = ../../../secrets-agenix/rclone-conf.age;
        target = ".local/share/agenix-user-secrets/rclone-conf";
      };
      proxmox-api-token = {
        source = ../../../secrets-agenix/proxmox-api-token.age;
        target = ".local/share/agenix-user-secrets/proxmox-api-token";
      };
    };
  };

  programs.distrobox.fedora.enable = true;

  my.just.flakeDir = unifiedMainWorktree;

  home.sessionVariables = {
    NH_FLAKE = lib.mkForce unifiedMainWorktree;
    MOTD_FLAKE_REPO = lib.mkForce unifiedMainWorktree;
  };

  programs.bash.shellAliases.cdflake = "cd ${unifiedMainWorktree}";
  programs.zsh.shellAliases.cdflake = "cd ${unifiedMainWorktree}";
  programs.fish = {
    shellAliases.cdflake = "cd ${unifiedMainWorktree}";
    interactiveShellInit = lib.mkAfter ''
      set -gx NH_FLAKE "${unifiedMainWorktree}"
      set -gx MOTD_FLAKE_REPO "${unifiedMainWorktree}"
    '';
  };
  programs.nushell = {
    environmentVariables = {
      NH_FLAKE = lib.mkForce unifiedMainWorktree;
      MOTD_FLAKE_REPO = lib.mkForce unifiedMainWorktree;
    };
    shellAliases.cdflake = "cd ${unifiedMainWorktree}";
  };
}
