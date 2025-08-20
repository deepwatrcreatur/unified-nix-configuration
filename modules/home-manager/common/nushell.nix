# modules/home-manager/common/nushell.nix
{ config, pkgs, lib, ... }:
{
  programs.nushell = {
    enable = true;
    environmentVariables = {
      GPG_TTY = "(tty)";
      GNUPGHOME = "${config.home.homeDirectory}/.gnupg";
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    };
    shellAliases = {
      rename = "^rename -n";
      rename-apply = "^rename";
    };
    configFile.text = ''
      # SSH auth socket setup
      if ($env.SSH_AUTH_SOCK | is-empty) and ("/opt/homebrew/bin/gpgconf" | path exists) {
        $env.SSH_AUTH_SOCK = (^/opt/homebrew/bin/gpgconf --list-dirs agent-ssh-socket | str trim)
      } else if ($env.SSH_AUTH_SOCK | is-empty) and ("/run/current-system/sw/bin/gpgconf" | path exists) {
        $env.SSH_AUTH_SOCK = (^/run/current-system/sw/bin/gpgconf --list-dirs agent-ssh-socket | str trim)
      }

      # Starship prompt integration
      $env.STARSHIP_SHELL = "nu"
      $env.PROMPT_COMMAND = { ||
          ^/usr/local/bin/starship prompt --cmd-duration $env.CMD_DURATION_MS $"--status=($env.LAST_EXIT_CODE)"
      }
      $env.PROMPT_COMMAND_RIGHT = { ||
          ^/usr/local/bin/starship prompt --right --cmd-duration $env.CMD_DURATION_MS $"--status=($env.LAST_EXIT_CODE)"
      }
    '';
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
      ] | where {|path| $path | path exists} | uniq)
    '';
  };
}
