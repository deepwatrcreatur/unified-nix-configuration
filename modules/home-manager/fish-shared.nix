# modules/home-manager/fish-shared.nix

{ config, pkgs, lib, ... }:
{
  programs.fish = {
    enable = true;

    shellAliases = {
      ls = "lsd";
      ll = "lsd -l";
      la = "lsd -a";
      lla = "lsd -la";
      ".." = "cd ..";
      update = "just --justfile ~/.justfile update";
      nh-update = "just --justfile ~/.justfile nh-update";
    };

    plugins = [
      { name = "fzf"; src = pkgs.fishPlugins.fzf; }
      { name = "z"; src = pkgs.fishPlugins.z; }
      { name = "puffer"; src = pkgs.fishPlugins.puffer; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair; }
      { name = "grc"; src = pkgs.fishPlugins.grc; }
    ];

    interactiveShellInit = ''
      # Set GPG_TTY for all systems
      set -gx GPG_TTY (tty)
    '';
  };
}
