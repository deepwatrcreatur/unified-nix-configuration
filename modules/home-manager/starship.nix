# modules/home-manager/starship.nix - Solid Bar Version
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
      
      # Format with solid bars
      format = "┌─$directory$git_branch$git_status$nix_shell$line_break└─$character";
      right_format = "$cmd_duration$time";
      
      # Directory with solid block bars
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        format = "▐$path▌($style) ";
        style = "bold cyan";
        truncation_symbol = "…/";
      };
      
      # Git branch with repository icon and solid styling
      git_branch = {
        format = "in ▐$symbol$branch▌($style)";
        symbol = "🗂 ";
        style = "bold purple";
      };
      
      # Git status with prominent staging indicator
      git_status = {
        format = "▐$all_status$ahead_behind▌($style) ";
        style = "bold yellow";
        conflicted = "≠";
        up_to_date = "✓";
        untracked = "?";
        ahead = "⇡\${count}";
        diverged = "⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
        stashed = "≡";
        modified = "!";
        staged = "✚";  # Prominent plus for staged
        renamed = "→";
        deleted = "✗";
      };
      
      # Nix shell with solid bars
      nix_shell = {
        format = "via ▐$symbol$name▌($style) ";
        symbol = "❄️ ";
        style = "bold blue";
        impure_msg = "impure";
        pure_msg = "pure";
      };
      
      # Classic prompt character
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        vicmd_symbol = "[❮](bold yellow)";
      };
      
      # Line break for two-line prompt
      line_break = {
        disabled = false;
      };
      
      # Command duration with solid styling
      cmd_duration = {
        format = "▐⏱ $duration▌($style) ";
        style = "yellow";
        min_time = 1000;
        show_milliseconds = false;
      };
      
      # Time with solid bars
      time = {
        disabled = false;
        format = "▐$time▌($style)";
        style = "bold white";
        time_format = "%H:%M:%S";
      };
      
      # Disable unwanted modules
      shell.disabled = true;
      username.disabled = true;
      hostname = {
        ssh_only = true;
        format = "▐$hostname▌($style) ";
        style = "bold green";
      };
    };
  };
}
