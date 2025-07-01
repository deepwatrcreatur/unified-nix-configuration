{ config, pkgs, lib, ... }:
{
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    GPG_TTY = "(tty)";
  };
  home.sessionPath = [
    "${config.home.homeDirectory}/.nix-profile/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];
  programs.nushell = {
    enable = true;
  };
  programs.fish = {
    enable = true;
  };
}
