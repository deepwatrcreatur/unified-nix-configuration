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
      # - Line 1: OS + user@host + git + memory ... right edge: cmd_duration then time
      # - Line 2: input character
      #
      # Keep it "colored text on dark background" (no solid background blocks).
      format =
        "$os $username$hostname $git_branch$git_status $memory_usage$fill$cmd_duration $time\n$character";

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

      os = {
        disabled = false;
        style = "fg:color_blue";
        format = "[$symbol]($style)";
        symbols = {
          Linux = "󰌽";
          NixOS = "󱄅";
          Macos = "󰀵";
        };
      };

      username = {
        show_always = true;
        style_user = "fg:color_yellow";
        style_root = "fg:color_red";
        format = "[$user]($style)";
      };

      hostname = {
        ssh_only = false;
        style = "fg:color_blue";
        format = "[@$hostname]($style)";
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

      memory_usage = {
        disabled = false;
        threshold = 0;
        symbol = "🧠 ";
        style = "fg:color_green";
        format = "[$symbol$ram]($style)";
      };

      cmd_duration = {
        disabled = false;
        min_time = 0;
        show_milliseconds = true;
        style = "fg:color_aqua";
        format = "[took $duration]($style)";
      };

      time = {
        disabled = false;
        style = "fg:color_gray";
        time_format = "%H:%M";
        format = "[$time]($style)";
      };

      character = {
        success_symbol = "[❯](bold color_green)";
        error_symbol = "[❯](bold color_red)";
        vicmd_symbol = "[❮](bold color_yellow)";
      };
    };
  };
}