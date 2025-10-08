# modules/home-manager/starship.nix - Minimal for External Preset Management
{ config, ... }:
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      command_timeout = 5000; # 5 second timeout for commands
      git_status = {
        disabled = false;
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
      };
      bun = {
        disabled = true;
      };
    };
  };
}
