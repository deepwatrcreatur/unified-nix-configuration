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

      # Custom prompt functions
      def create_left_prompt [] {
        let dir = match (do --ignore-errors { $env.PWD | path relative-to $nu.home-path }) {
          null => $env.PWD
          "" => "~"
          $relative_pwd => ([~ $relative_pwd] | path join)
        }

        let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
        let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi light_green_bold })
        let path_segment = $"($path_color)($dir)"

        $path_segment | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"
      }

      def create_right_prompt [] {
        # create a right prompt in magenta with green separators and am/pm underlined
        let time_segment = ([
          (ansi reset)
          (ansi magenta)
          (date now | format date "%x %X") # try to respect user's locale
        ] | str join | str replace --regex --all "([/:])" $"(ansi green)$1(ansi magenta)" |
          str replace --regex --all "([AP]M)" $"(ansi magenta_underline)$1")

        let last_exit_code = if ($env.LAST_EXIT_CODE != 0) {([
          (ansi rb)
          ($env.LAST_EXIT_CODE)
        ] | str join)
        } else { "" }

        ([$last_exit_code, (char space), $time_segment] | str join)
      }

      # Use custom prompt functions
      $env.PROMPT_COMMAND = {|| create_left_prompt }
      $env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }

      # SSH auth socket setup
      if ($env.SSH_AUTH_SOCK | is-empty) and ("/opt/homebrew/bin/gpgconf" | path exists) {
        $env.SSH_AUTH_SOCK = (^/opt/homebrew/bin/gpgconf --list-dirs agent-ssh-socket | str trim)
      } else if ($env.SSH_AUTH_SOCK | is-empty) and ("/run/current-system/sw/bin/gpgconf" | path exists) {
        $env.SSH_AUTH_SOCK = (^/run/current-system/sw/bin/gpgconf --list-dirs agent-ssh-socket | str trim)
      }

      # Starship prompt integration (commented out - using custom prompt instead)
      # $env.STARSHIP_SHELL = "nu"
      # $env.PROMPT_COMMAND = { ||
      #     ^/usr/local/bin/starship prompt --cmd-duration $env.CMD_DURATION_MS $"--status=($env.LAST_EXIT_CODE)"
      # }
      # $env.PROMPT_COMMAND_RIGHT = { ||
      #     ^/usr/local/bin/starship prompt --right --cmd-duration $env.CMD_DURATION_MS $"--status=($env.LAST_EXIT_CODE)"
      # }
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
