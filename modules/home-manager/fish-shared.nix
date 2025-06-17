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

    # The bobthefish plugin has been removed from this list
    plugins = [
      { name = "fzf"; src = pkgs.fishPlugins.fzf; }
      { name = "z"; src = pkgs.fishPlugins.z; }
      { name = "puffer"; src = pkgs.fishPlugins.puffer; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair; }
      { name = "grc"; src = pkgs.fishPlugins.grc; }
    ];

    # This block is now much cleaner!
    interactiveShellInit = ''
      if test -e $HOME/.nix-profile/etc/profile.d/hm-session-vars.fish
        source $HOME/.nix-profile/etc/profile.d/hm-session-vars.fish
      end
      # We still keep this here as it's a general shell setting
      set -gx GPG_TTY (tty)
    '';
  };
}
