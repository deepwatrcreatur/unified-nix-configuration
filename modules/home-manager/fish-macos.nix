# modules/home-manager/fish-macos.nix

{ config, pkgs, lib, ... }:
{
  programs.fish = {
    enable = true;

    interactiveShellInit = lib.mkAfter ''
      set -gx PATH
      set -gx PATH /opt/homebrew/bin /opt/homebrew/opt/mise/bin $PATH

      # Add macOS system paths
      set -gx PATH /usr/bin /bin /usr/sbin /sbin /usr/local/bin

      # Add Nix paths (system and user)
      if test -d /run/current-system/sw/bin
        set -gx PATH /run/current-system/sw/bin $PATH
      end
      if test -d /nix/var/nix/profiles/default/bin
        set -gx PATH /nix/var/nix/profiles/default/bin $PATH
      end
      if test -d /Users/deepwatrcreatur/.nix-profile/bin
        set -gx PATH /Users/deepwatrcreatur/.nix-profile/bin $PATH
      end

      # Add other user-specific paths
      set -gx PATH /Users/deepwatrcreatur/.cargo/bin /usr/local/MacGPG2/bin /Applications/Ghostty.app/Contents/MacOS $PATH

      # Add Cryptex paths (macOS-specific)
      set -gx PATH /System/Cryptexes/App/usr/bin /var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin /var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin /var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin $PATH

      # Environment variables (from hm-session-vars.sh)
      set -gx EDITOR hx
      set -gx VISUAL hx
      set -gx GNUPGHOME /Users/deepwatrcreatur/.gnupg

      # Set SSH_AUTH_SOCK
      if test -z "$SSH_AUTH_SOCK" -a -x /opt/homebrew/bin/gpgconf
        set -gx SSH_AUTH_SOCK (/opt/homebrew/bin/gpgconf --list-dirs agent-ssh-socket | string trim)
      else if test -z "$SSH_AUTH_SOCK" -a -x /run/current-system/sw/bin/gpgconf
        set -gx SSH_AUTH_SOCK (/run/current-system/sw/bin/gpgconf --list-dirs agent-ssh-socket | string trim)
      end
    '';
  };

  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    GNUPGHOME = "/Users/deepwatrcreatur/.gnupg";
  };
}
