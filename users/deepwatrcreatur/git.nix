# modules/git.nix
{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    userName = "Anwer Khan";
    userEmail = "deepwatrcreatur@gmail.com";
    # Add more git config here if needed
  };
}

