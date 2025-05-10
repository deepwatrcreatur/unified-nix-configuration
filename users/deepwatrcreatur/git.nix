# modules/git.nix
{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    userName = "Anwer Khan";
    userEmail = "deepwatrcreatur@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "hx";
    };

    aliases = {
      co = "checkout";
      br = "branch";
      ci = "commit";
      st = "status";
    };   
  };
}
