# modules/home-manager/starship.nix
{ config, ... }:
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      command_timeout = 1000;
      scan_timeout = 30;
      
      # Boxed format with double bars
      format = "╭─[$directory$git_branch$git_status$nix_shell]─╮\n╰─$character";
      
      # Directory with classic path display
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        format = "$path";
        style = "bold cyan";
      };
      
      # Git branch 
      git_branch = {
        format = " [$symbol$branch]($style)";
        symbol = "";
        style = "bold purple";
      };
      
      # Classic git status symbols
      git_status = {
        format = " [$all_status$ahead_behind]($style)";
        style = "bold yellow";
        conflicted = "=";
        up_to_date = "";
        untracked = "?";
        ahead = "↑\${count}";
        diverged = "↑\${ahead_count}↓\${behind_count}";
        behind = "↓\${count}";
        stashed = "\\$";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "x";
      };
      
      # Nix shell
      nix_shell = {
        format = " [$symbol]($style)";
        symbol = "❄️";
        style = "bold blue";
      };
      
      # Arrow prompt
      character = {
        success_symbol = "[→](bold green)";
        error_symbol = "[→](bold red)";
        vicmd_symbol = "[←](bold yellow)";
      };
      
      # Disable extras
      shell.disabled = true;
      username.disabled = true;
      hostname.ssh_only = true;
      cmd_duration.disabled = true;
      time.disabled = true;
    };
  };
}
