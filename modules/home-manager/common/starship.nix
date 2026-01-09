# modules/home-manager/starship.nix - Clean Starship prompt with gruvbox theme
{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;

      # Two-line prompt:
      # - Line 1: language + git branch/status ... right edge: cmd_duration + exit_status
      # - Line 2: input character
      #
      # Context moved to zellij top bar: OS + user@host + memory
      # Directory shown at top of zellij pane (current working directory)
      # Keep it "colored text on dark background" (no solid background blocks).
      format =
        "$nix$env_var$rust$nodejs$python$golang$git_branch$git_status$fill$cmd_duration$status\n$character";

      # Palettes
      palette = "kanagawa";
      palettes = {
        gruvbox_dark = {
          color_fg0 = "#ebdbb2";
          color_bg0 = "#282828";
          color_red = "#cc241d";
          color_green = "#98971a";
          color_yellow = "#d79921";
          color_blue = "#458588";
          color_purple = "#b16286";
          color_aqua = "#689d6a";
          color_gray = "#a89984";
        };

        # Kanagawa-inspired colors (dark background, readable accents)
        kanagawa = {
          color_fg0 = "#dcd7ba";
          color_bg0 = "#1f1f28";
          color_red = "#c34043";
          color_green = "#76946a";
          color_yellow = "#c0a36e";
          color_blue = "#7e9cd8";
          color_purple = "#957fb8";
          color_aqua = "#6a9589";
          color_gray = "#727169";
        };
      };

      # Right-edge alignment helper (invisible fill)
      fill = {
        symbol = " ";
        style = "fg:color_bg0";
      };

      # OS, username, hostname moved to zellij top bar
      os = {
        disabled = true;
      };

      username = {
        disabled = true;
      };

      hostname = {
        disabled = true;
      };

      git_branch = {
        disabled = false;
        symbol = " ";
        style = "fg:color_purple";
        format = "[$symbol$branch]($style)";
      };

      git_status = {
        disabled = false;
        style = "fg:color_red";
        format = "([ $all_status$ahead_behind ]($style))";
      };

      # Memory moved to zellij top bar
      memory_usage = {
        disabled = true;
      };

      # Command duration on right edge of starship
      cmd_duration = {
        disabled = false;
        min_time = 0;
        show_milliseconds = true;
        style = "fg:color_aqua";
        format = "[took $duration]($style)";
      };

      # Exit status indicator (✓ or ✗ based on last command)
      status = {
        disabled = false;
        symbol = "✗";
        success_symbol = "✓";
        format = "[$symbol]($style)";
        style = "fg:color_red";
        map_symbol = true;
      };

      # Time moved to zellij top bar (redundant with desktop clock)
      time = {
        disabled = true;
      };

      # Language modules to show project context
      rust = {
        disabled = false;
        symbol = "🦀 ";
        style = "fg:color_red";
        format = "[$symbol]($style)";
      };

      nodejs = {
        disabled = false;
        symbol = " ";
        style = "fg:color_green";
        format = "[$symbol]($style)";
      };

      python = {
        disabled = false;
        symbol = "🐍 ";
        style = "fg:color_yellow";
        format = "[$symbol]($style)";
      };

      golang = {
        disabled = false;
        symbol = "🐹 ";
        style = "fg:color_blue";
        format = "[$symbol]($style)";
      };

      # Nix development environment - shows when in nix develop/nix shell
      nix_shell = {
        disabled = false;
        symbol = "❄️  ";
        style = "fg:color_aqua";
        format = "[$symbol$name]($style)";
      };

      # Virtual environments - detects VIRTUAL_ENV when in Python venv
      env_var.VIRTUAL_ENV = {
        symbol = "🐍 ";
        style = "fg:color_yellow";
        format = "[$symbol($env_value)]($style)";
      };

      character = {
        success_symbol = "[❯](bold color_green)";
        error_symbol = "[❯](bold color_red)";
        vicmd_symbol = "[❮](bold color_yellow)";
      };
    };
  };
}