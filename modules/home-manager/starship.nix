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
      
      # Classic shell format with bars
      format = "┌─$directory$git_branch$git_status$nix_shell$line_break└─$character";
      
      # Directory with classic path display
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        format = "$path";
        style = "bold cyan";
      };
      
      # Git branch with classic formatting
      git_branch = {
        format = " on [$symbol$branch]($style)";
        symbol = "";
        style = "bold purple";
      };
      
      # Classic git status with + and ? symbols
      git_status = {
        format = "[$all_status$ahead_behind]($style)";
        style = "bold red";
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
        deleted = "✘";
      };
      
      # Nix shell indicator
      nix_shell = {
        format = " via [$symbol$name]($style)";
        symbol = "❄️ ";
        style = "bold blue";
        impure_msg = "impure";
        pure_msg = "pure";
      };
      
      # Classic prompt character
      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[>](bold red)";
        vicmd_symbol = "[<](bold yellow)";
      };
      
      # Clean up - disable extras
      shell.disabled = true;
      username.disabled = true;
      hostname = {
        ssh_only = true;
        format = "at [$hostname]($style) ";
        style = "bold green";
      };
      cmd_duration.disabled = true;
      time.disabled = true;
    };
  };
}
