# modules/home-manager/nushell-macos.nix

{ config, pkgs, lib, ... }:
{
  programs.nushell = {
    enable = true;
    configFile.text = lib.mkAfter ''
      # MacOS-specific Nushell configuration
      let-env PATH = ($env.PATH | split row (char path_sep) | prepend [
        "/opt/homebrew/bin",                     # Homebrew (Fish, cmake)
        "/opt/homebrew/opt/mise/bin",            # Mise
        "/run/current-system/sw/bin",            # nix-darwin system packages
        "/nix/var/nix/profiles/default/bin",     # Nix tools
        "/Users/deepwatrcreatur/.nix-profile/bin", # Home Manager packages
        "/usr/bin",
        "/bin",
        "/usr/sbin",
        "/sbin",
        "/usr/local/bin",
        "/Users/deepwatrcreatur/.cargo/bin",
        "/usr/local/MacGPG2/bin",
        "/Applications/Ghostty.app/Contents/MacOS",
        "/System/Cryptexes/App/usr/bin",
        "/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin",
        "/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin",
        "/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin"
      ] | filter { |path| $path | path exists } | str join (char path_sep))

      let-env EDITOR = "hx"
      let-env VISUAL = "hx"
      let-env GNUPGHOME = "/Users/deepwatrcreatur/.gnupg"

      if ($env.SSH_AUTH_SOCK | is-empty) and ("/opt/homebrew/bin/gpgconf" | path exists) {
        let-env SSH_AUTH_SOCK = ("/opt/homebrew/bin/gpgconf" --list-dirs agent-ssh-socket | str trim)
      } else if ($env.SSH_AUTH_SOCK | is-empty) and ("/run/current-system/sw/bin/gpgconf" | path exists) {
        let-env SSH_AUTH_SOCK = ("/run/current-system/sw/bin/gpgconf" --list-dirs agent-ssh-socket | str trim)
      }
    '';
  };
}
