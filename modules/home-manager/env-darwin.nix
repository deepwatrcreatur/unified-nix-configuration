{ config, pkgs, lib, ... }:
{
  home.sessionPath = [
    "/opt/homebrew/bin"
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

  home.file = {
    "Library/Application Support/nushell/config.nu".source = pkgs.writeTextFile {
      name = "nushell-config";
      text = ''
        $env.GNUPGHOME = "${config.home.homeDirectory}/.gnupg"
        $env.SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt"
        if ($env.SSH_AUTH_SOCK | is-empty) and ("/opt/homebrew/bin/gpgconf" | path exists) {
          $env.SSH_AUTH_SOCK = (^/opt/homebrew/bin/gpgconf --list-dirs agent-ssh-socket | str trim)
        } else if ($env.SSH_AUTH_SOCK | is-empty) and ("/run/current-system/sw/bin/gpgconf" | path exists) {
          $env.SSH_AUTH_SOCK = (^/run/current-system/sw/bin/gpgconf --list-dirs agent-ssh-socket | str trim)
        }
        
        # Add starship initialization
        source ~/.cache/starship/init.nu
      '';
    };
    "Library/Application Support/nushell/env.nu".source = pkgs.writeTextFile {
      name = "nushell-env";
      text = "";
    };
  };
  programs.nushell = {
    envFile.text = ''
      # Set up PATH with all required directories
      $env.PATH = ($env.PATH | split row (char esep) | prepend [
        "${config.home.homeDirectory}/.nix-profile/bin"
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
      ] | uniq)
      
      # Set environment variables
      $env.GNUPGHOME = "${config.home.homeDirectory}/.gnupg"
      $env.SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt"
    '';
  };
  programs.fish = {
    interactiveShellInit = ''
      set -gx GNUPGHOME ${config.home.homeDirectory}/.gnupg
      set -gx SOPS_AGE_KEY_FILE ${config.home.homeDirectory}/.config/sops/age/keys.txt
      if test -z "$SSH_AUTH_SOCK" -a -x /opt/homebrew/bin/gpgconf
        set -gx SSH_AUTH_SOCK (/opt/homebrew/bin/gpgconf --list-dirs agent-ssh-socket | str trim)
      else if test -z "$SSH_AUTH_SOCK" -a -x /run/current-system/sw/bin/gpgconf
        set -gx SSH_AUTH_SOCK (/run/current-system/sw/bin/gpgconf --list-dirs agent-ssh-socket | str trim)
      end
    '';
  };
}
