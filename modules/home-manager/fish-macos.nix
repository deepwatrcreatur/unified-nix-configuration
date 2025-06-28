# modules/home-manager/fish-macos.nix

{ config, pkgs, lib, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = lib.mkAfter ''
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

  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/opt/mise/bin" # Consider if this is still relevant with Nix/home-manager
    
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
    "/usr/local/bin"

    "/run/current-system/sw/bin" # System-wide Nix path
    "/nix/var/nix/profiles/default/bin" # Default Nix profile path

    "$HOME/.cargo/bin"
    "/usr/local/MacGPG2/bin"
    "/Applications/Ghostty.app/Contents/MacOS"

    # Cryptex paths (macOS-specific)
    "/System/Cryptexes/App/usr/bin"
    "/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin"
    "/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin"
    "/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin"

    "$HOME/.npm-global/bin"
  ];

}
