# modules/home-manager/nushell/default.nix

{ config, pkgs, lib, ... }:

{
  programs.nushell = {
    enable = true;
    environmentVariables = {
      GPG_TTY = "(tty)";
    };
    shellAliases = {
      rename = "^rename -n";
      rename-apply = "^rename";
    };
  };
}
