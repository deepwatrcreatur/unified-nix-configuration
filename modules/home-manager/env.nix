{ config, pkgs, lib, ... }:
{
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    GPG_TTY = "(tty)";
  };
  home.sessionPath = [
    "${config.home.homeDirectory}/.nix-profile/bin"
  ];
  programs.nushell = {
    enable = true;
  };
  programs.fish = {
    enable = true;
  };
}
