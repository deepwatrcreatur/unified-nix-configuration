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

  # Add jj and lazyjj to home.packages
  home.packages = with pkgs; [
    jujutsu
    lazyjj  
  ];
}
