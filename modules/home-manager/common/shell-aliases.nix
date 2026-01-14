# modules/home-manager/shell-aliases.nix
{
  config,
  lib,
  ...
}:
let
  # Merge all alias modules
  aliases =
    config.custom.fileAliases.aliases
    // config.custom.gitAliases.aliases
    // config.custom.navigationAliases.aliases
    // config.custom.toolAliases.aliases
    // config.custom.grc.aliases;

  # Raw variants that bypass wrapped aliases
  rawAliasesPosix = {
    gh-raw = "command gh";
    opencode-raw = "command opencode";
  };

  rawAliasesNushell = {
    gh-raw = "^gh";
    opencode-raw = "^opencode";
  };
in
{
  imports = [
    ./file-aliases.nix
    ./git-aliases.nix
    ./navigation-aliases.nix
    ./tool-aliases.nix
    ./grc.nix
  ];

  programs = {
    bash = {
      enable = true;
      shellAliases = aliases // rawAliasesPosix;
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
      shellAliases = aliases // rawAliasesPosix;
      initContent = ''
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
    fish = {
      shellAliases = aliases // rawAliasesPosix;
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

  # Handle nushell - use shellAliases for all commands
  programs.nushell = {
    # Merge all aliases for nushell (use mkForce to override conflicts)
    shellAliases = lib.mkForce (
      # Convert bash/zsh style aliases to nushell format
      (lib.mapAttrs (name: value: "^${value}") config.custom.fileAliases.aliases)
      // (lib.mapAttrs (name: value: "^${value}") config.custom.gitAliases.aliases)
      // (lib.mapAttrs (name: value: value) config.custom.navigationAliases.aliases)
      # Navigation doesn't need ^
      // (lib.mapAttrs (name: value: "^${value}") config.custom.toolAliases.aliases)
      // config.custom.grc.nushellAliases
      // rawAliasesNushell
    );

    extraConfig = ''
      # Start SSH agent if not already running
      if (not ($env | get SSH_AUTH_SOCK | is-empty)) or (do { ssh-add -l } | complete | get exit_code) != 0 {
        let ssh_agent_output = (^ssh-agent -c | str trim)
        # Parse the csh-style output to extract environment variables
        for line in ($ssh_agent_output | lines) {
          if ($line | str starts-with "setenv SSH_AUTH_SOCK") {
            $env.SSH_AUTH_SOCK = ($line | str replace "setenv SSH_AUTH_SOCK " "" | str replace ";" "")
          } else if ($line | str starts-with "setenv SSH_AGENT_PID") {
            $env.SSH_AGENT_PID = ($line | str replace "setenv SSH_AGENT_PID " "" | str replace ";" "")
          }
        }
        # Try to add common SSH keys
        for key in [$"($env.HOME)/.ssh/id_ed25519" $"($env.HOME)/.ssh/id_rsa"] {
          if ($key | path exists) {
            ssh-add $key | ignore
          }
        }
      }

      # KiloCode launcher with proper terminal settings
      def kilocode [...args] {
        # Set environment variables for better terminal compatibility
        $env.TERM = "xterm-256color"
        $env.COLORTERM = "truecolor"
        $env.NODE_OPTIONS = "--max-old-space-size=4096"
        $env.NODE_NO_WARNINGS = "1"
        # Fix backspace and terminal input issues
        $env.STTY = "erase ^?"
        $env.LC_ALL = "en_US.UTF-8"
        $env.LANG = "en_US.UTF-8"
        
        # Launch KiloCode with cleaned environment
        ^kilocode ...$args
      }
    '';
  };
}
