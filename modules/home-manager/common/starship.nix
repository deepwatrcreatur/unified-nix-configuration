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
      command_timeout = 1000; # 1 second timeout for git commands
    };
  };
}
