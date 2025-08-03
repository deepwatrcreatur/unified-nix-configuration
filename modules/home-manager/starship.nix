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
      
      # Developer-focused format with runtime info
      format = "$directory$git_branch$git_status$nix_shell$nodejs$python$rust$golang$character";
      right_format = "$cmd_duration$time";
      
      # Directory with folder icon
      directory = {
        truncation_length = 4;
        truncate_to_repo = true;
        format = "[📁 $path]($style) ";
        style = "bold cyan";
        repo_root_style = "bold blue";
      };
      
      # Git information
      git_branch = {
        format = "[ $symbol$branch]($style) ";
        symbol = "";
        style = "bold purple";
      };
      
      git_status = {
        format = "[$all_status$ahead_behind]($style) ";
        style = "bold yellow";
        conflicted = "💥";
        up_to_date = "✓";
        untracked = "?";
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
        stashed = "📦";
        modified = "📝";
        staged = "+";
        renamed = "→";
        deleted = "✗";
      };
      
      # Runtime versions
      nodejs = {
        format = "[⬢ $version]($style) ";
        style = "bold green";
      };
      
      python = {
        format = "[🐍 $version]($style) ";
        style = "bold yellow";
      };
      
      rust = {
        format = "[🦀 $version]($style) ";
        style = "bold red";
      };
      
      golang = {
        format = "[🐹 $version]($style) ";
        style = "bold cyan";
      };
      
      # Nix shell
      nix_shell = {
        format = "[❄️ $name]($style) ";
        style = "bold blue";
        impure_msg = "impure";
        pure_msg = "pure";
      };
      
      # Command duration on right
      cmd_duration = {
        format = "[⏱ $duration]($style)";
        style = "yellow";
        min_time = 2000;
      };
      
      # Time on right
      time = {
        disabled = false;
        format = "[ $time]($style)";
        style = "bold white";
        time_format = "%T";
      };
      
      # Prompt character
      character = {
        success_symbol = "[▶](bold green)";
        error_symbol = "[▶](bold red)";
        vicmd_symbol = "[◀](bold yellow)";
      };
      
      # Clean up unwanted modules
      shell.disabled = true;
      username.disabled = true;
      hostname = {
        ssh_only = true;
        format = "[🌐 $hostname]($style) ";
        style = "bold green";
      };
    };
  };
}
