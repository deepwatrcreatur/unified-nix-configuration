{ config, pkgs, ... }:

let
  aliases = import ./aliases.nix;
in
{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Anwer Khan";
        email = "deepwatrcreatur@gmail.com";
      };
      aliases = aliases;
    };
  };
}
