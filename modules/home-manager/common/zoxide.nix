{
  config,
  lib,
  pkgs,
  ...
}:

{
  # No options needed, just direct configuration
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
  };
}
