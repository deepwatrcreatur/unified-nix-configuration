# modules/home-manager/nushell-shared.nix

{ config, pkgs, lib, ... }:
{
  programs.nushell = {
    enable = true;
    environmentVariables = {
      GPG_TTY = "(tty)";
    };
    shellAliases = {
      update = "just update";
      nh-update = "just nh-update";
      ls = "lsd";
      ll = "lsd -l";
      la = "lsd -a";
      lla = "lsd -la";
      ".." = "cd ..";
    };
  };

  programs.starship = {
    enableNushellIntegration = true;
  };
}
