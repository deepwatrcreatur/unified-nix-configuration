# modules/home-manager/env-darwin.nix
{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.sessionPath = [
    "${config.platform.homebrewPrefix}/bin"
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

  # Set environment variables for the session
  home.sessionVariables = {
    GNUPGHOME = "${config.home.homeDirectory}/.gnupg";
    SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  # Only fish configuration here - nushell is handled by the nushell module
  programs.fish = {
    shellAliases = {
      fish = "/nix/var/nix/profiles/system/sw/bin/fish";
    };

    # shellInit runs for ALL fish shells - critical for SSH sessions on macOS
    shellInit = lib.mkBefore ''
      # Add nix-darwin per-user profile (CRITICAL for SSH sessions)
      fish_add_path --prepend --move /etc/profiles/per-user/${config.home.username}/bin
      # Add macOS-specific paths
      fish_add_path --prepend --move ${config.platform.homebrewPrefix}/bin
      fish_add_path --prepend --move /usr/local/bin
    '';

    interactiveShellInit = ''
      set -gx GNUPGHOME ${config.home.homeDirectory}/.gnupg
      set -gx SOPS_AGE_KEY_FILE ${config.home.homeDirectory}/.config/sops/age/keys.txt
      if test -z "$SSH_AUTH_SOCK" -a -x ${config.platform.homebrewPrefix}/bin/gpgconf
        set -gx SSH_AUTH_SOCK (${config.platform.homebrewPrefix}/bin/gpgconf --list-dirs agent-ssh-socket | str trim)
      else if test -z "$SSH_AUTH_SOCK" -a -x /run/current-system/sw/bin/gpgconf
        set -gx SSH_AUTH_SOCK (/run/current-system/sw/bin/gpgconf --list-dirs agent-ssh-socket | str trim)
      end
    '';
  };
}
