{ config, lib, pkgs, ... }:

with lib;

{
  # Define options for the module
  options.programs.zoxide = {
    enable = mkEnableOption "zoxide, a smarter cd command";

    enableBashIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Enable zoxide integration for bash.";
    };

    enableZshIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Enable zoxide integration for zsh.";
    };

    enableFishIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Enable zoxide integration for fish.";
    };

    enableNushellIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Enable zoxide integration for nushell.";
    };
  };
}
