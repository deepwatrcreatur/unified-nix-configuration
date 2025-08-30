{ config, pkgs, lib, ... }:
{
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    GPG_TTY = "(tty)";
    NH_FLAKE = "${config.home.homeDirectory}/unified-nix-configuration";
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
