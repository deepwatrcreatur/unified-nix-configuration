# modules/home-manager/starship.nix - Enhanced Starship Configuration
{ config, ... }:
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      # Enhanced left prompt with user, host, os, directory, git, and character
      format = "[($username@)]($style)[($hostname)]($style)[$os]($style)[$directory]($style)[$git_branch]($style)$character";
      palette = "catppuccin_mocha";
      # Move the rest of the prompt to the right with time
      right_format = "$all$time";
      command_timeout = 1000;

      character = {
        vicmd_symbol = "[N] >>>";
        success_symbol = "[➜](bold green)";
        error_symbol = "[❯](bold red)";
      };

      directory = {
        style = "cyan bold";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      username = {
        show_always = true;
        style_user = "yellow bold";
        style_root = "red bold";
        format = "[$user]($style)";
      };

      hostname = {
        ssh_only = false;
        style = "blue bold";
        format = "[$hostname]($style)";
      };

      os = {
        style = "peach";
        disabled = false;
        format = "[$symbol]($style)";
      };

      git_branch = {
        format = "[$symbol$branch]($style)";
        style = "mauve";
      };

      git_status = {
        disabled = false;
        style = "red bold";
        format = "([\\[$all_status$ahead_behind\\]]($style) )";
      };

      aws = {
        format = "[$symbol($profile )(\\(region: $region\\) )]($style)";
        disabled = false;
        style = "blue";
        symbol = " ";
      };

      golang = {
        format = "[ ](cyan)";
      };

      kubernetes = {
        symbol = "☸ ";
        disabled = true;
        detect_files = ["Dockerfile"];
        format = "[$symbol$context( \\($namespace\\))]($style) ";
        contexts = [
          { context_pattern = "arn:aws:eks:us-west-2:577926974532:cluster/zd-pvc-omer"; style = "green"; context_alias = "omerxx"; symbol = " "; }
        ];
      };

      docker_context = {
        disabled = true;
      };

      time = {
        disabled = false;
        format = "at [$time]($style) ";
        style = "yellow";
        time_format = "%I:%M %p";
      };

      bun = {
        disabled = true;
      };

      palettes.catppuccin_mocha = {
        rosewater = "#f5e0dc";
        flamingo = "#f2cdcd";
        pink = "#f5c2e7";
        mauve = "#cba6f7";
        red = "#f38ba8";
        maroon = "#eba0ac";
        peach = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        teal = "#94e2d5";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#89b4fa";
        lavender = "#b4befe";
        text = "#cdd6f4";
        subtext1 = "#bac2de";
        subtext0 = "#a6adc8";
        overlay2 = "#9399b2";
        overlay1 = "#7f849c";
        overlay0 = "#6c7086";
        surface2 = "#585b70";
        surface1 = "#45475a";
        surface0 = "#313244";
        base = "#1e1e2e";
        mantle = "#181825";
        crust = "#11111b";
      };
    };
  };
}
