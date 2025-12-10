# modules/home-manager/shell-aliases.nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  aliases = {
    ls = "lsd";
    ll = "lsd -l";
    la = "lsd -a";
    lla = "lsd -la";
    ".." = "cd ..";
    bp = "bat --paging=never --plain";
    update = "just --justfile ~/.justfile update";
    nh-update = "just --justfile ~/.justfile nh-update";
    ssh-nocheck = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ";
    rsync = "/run/current-system/sw/bin/rsync";
  }
  // lib.optionalAttrs pkgs.stdenv.isDarwin {
    xcode = "open -a Xcode";
  };
in
{
  programs = {
    bash = {
      shellAliases = aliases;
      initExtra = ''
        # Start SSH agent if not already running
        if [ -z "$SSH_AUTH_SOCK" ] || ! ssh-add -l >/dev/null 2>&1; then
          eval "$(ssh-agent -s)" >/dev/null
          # Try to add common SSH keys
          for key in ~/.ssh/id_ed25519 ~/.ssh/id_rsa; do
            if [ -f "$key" ]; then
              ssh-add "$key" >/dev/null 2>&1
            fi
          done
        fi
      '';
    };
    zsh = {
      shellAliases = aliases;
      initExtra = ''
        # Start SSH agent if not already running
        if [[ -z $SSH_AUTH_SOCK ]] || ! ssh-add -l >/dev/null 2>&1; then
          eval "$(ssh-agent -s)" >/dev/null
          # Try to add common SSH keys
          for key in ~/.ssh/id_ed25519 ~/.ssh/id_rsa; do
            if [[ -f $key ]]; then
              ssh-add "$key" >/dev/null 2>&1
            fi
          done
        fi
      '';
    };
    fish = {
      shellAliases = aliases;
      interactiveShellInit = ''
        # Start SSH agent if not already running
        if not set -q SSH_AUTH_SOCK; or not ssh-add -l >/dev/null 2>&1
          eval (ssh-agent -c) >/dev/null
          # Try to add common SSH keys
          for key in ~/.ssh/id_ed25519 ~/.ssh/id_rsa
            if test -f $key
              ssh-add $key >/dev/null 2>&1
            end
          end
        end
      '';
    };
  };

  # Handle nushell separately with proper syntax
  programs.nushell = {
    extraConfig = ''
      alias ls = ^lsd
      alias ll = ^lsd -l
      alias la = ^lsd -a
      alias lla = ^lsd -la
      alias bp = ^bat --paging=never --plain
      alias ".." = cd ..
      alias update = ^just --justfile ~/.justfile update
      alias nh-update = ^just --justfile ~/.justfile nh-update
      alias ssh-nocheck = ^ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
      alias rsync = ^/run/current-system/sw/bin/rsync
      ${lib.optionalString pkgs.stdenv.isDarwin "alias xcode = ^open -a Xcode"}

      # Start SSH agent if not already running
      if (not ($env | get SSH_AUTH_SOCK | is-empty)) or (do { ssh-add -l } | complete | get exit_code) != 0 {
        ^ssh-agent -c | save -f /tmp/ssh-agent.fish
        source /tmp/ssh-agent.fish
        # Try to add common SSH keys
        for key in [~/.ssh/id_ed25519 ~/.ssh/id_rsa] {
          if ($key | path exists) {
            ssh-add $key
          }
        }
      }
    '';
  };
}
