# modules/home-manager/env.nix

{ config, pkgs, lib, ... }:

{
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    GPG_TTY = "(tty)";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.nix-profile/bin"
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/.npm-global/bin"
  ] ++ lib.option two systems (pkgs.stdenv.isDarwin) [
    "/opt/homebrew/bin"
    "/opt/homebrew/opt/mise/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
    "/usr/local/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "/usr/local/MacGPG2/bin"
    "/Applications/Ghostty.app/Contents/MacOS"
    "/System/Cryptexes/App/usr/bin"
    "/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin"
    "/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin"
    "/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin"
  ];

  programs.nushell = {
    enable = true;
    configFile.text = lib.mkIf (pkgs.stdenv.isDarwin) ''
      let-env GNUPGHOME = "${config.home.homeDirectory}/.gnupg"

      if ($env.SSH_AUTH_SOCK | is-empty) and ("/opt/homebrew/bin/gpgconf" | path exists) {
        let-env SSH_AUTH_SOCK = ("/opt/homebrew/bin/gpgconf" --list-dirs agent-ssh-socket | str trim)
      } else if ($env.SSH_AUTH_SOCK | is-empty) and ("/run/current-system/sw/bin/gpgconf" | path exists) {
        let-env SSH_AUTH_SOCK = ("/run/current-system/sw/bin/gpgconf" --list-dirs agent-ssh-socket | str trim)
      }
    '';
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = lib.mkIf (pkgs.stdenv.isDarwin) ''
      set -gx GNUPGHOME ${config.home.homeDirectory}/.gnupg

      if test -z "$SSH_AUTH_SOCK" -a -x /opt/homebrew/bin/gpgconf
        set -gx SSH_AUTH_SOCK (/opt/homebrew/bin/gpgconf --list-dirs agent-ssh-socket | string trim)
      else if test -z "$SSH_AUTH_SOCK" -a -x /run/current-system/sw/bin/gpgconf
        set -gx SSH_AUTH_SOCK (/run/current-system/sw/bin/gpgconf --list-dirs agent-ssh-socket | string trim)
      end
    '';
  };
}
