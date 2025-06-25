{ config, lib, pkgs, ... }:

with lib;

{
  # This module doesn't declare new options, it just configures existing ones
  config = mkIf config.programs.zoxide.enable {
    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
    };
  };
}
