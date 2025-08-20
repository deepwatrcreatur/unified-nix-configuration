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
      l = "ls --all";
      c = "clear";
      ll = "ls -l";
    };
    configFile.text = ''
      # Enhanced table display
      $env.config.table = {
        mode: rounded
        index_mode: always
        show_empty: true
        padding: { left: 1, right: 1 }
        trim: {
          methodology: wrapping
          wrapping_try_keep_words: true
          truncating_suffix: "..."
        }
      }

      # Better completions
      $env.config.completions = {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "prefix"
        use_ls_colors: true
      }

      # Enhanced shell integration
      $env.config.shell_integration = {
        osc2: true   # sets tab/window title
        osc7: true   # communicates path to terminal
        osc8: true   # clickable links
        osc133: true # prompt markers for smart terminals
      }

      # Better history settings
      $env.config.history = {
        max_size: 100_000
        sync_on_enter: true
        file_format: "plaintext"
      }

      # Useful navigation function: cd + ls
      def --env cx [arg] {
        cd $arg
        ls -l
      }

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
      # Better PATH handling with environment conversions
      $env.ENV_CONVERSIONS = {
        "PATH": {
          from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
          to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
        }
        "Path": {
          from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
          to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
        }
      }

      # Set up PATH with all required directories (simplified due to conversions)
      $env.PATH = ($env.PATH | prepend [
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
