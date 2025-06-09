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
      { name = "bobthefish"; src = pkgs.fishPlugins.bobthefish; }
    ];

    # This block is what makes the home.sessionVariables work!
    interactiveShellInit = ''
      if test -e $HOME/.nix-profile/etc/profile.d/hm-session-vars.fish
        source $HOME/.nix-profile/etc/profile.d/hm-session-vars.fish
      end
      set -g theme_color_scheme solarized
      set -g theme_powerline_fonts no
      set -g theme_project_dir_length 1
      set -g theme_show_exit_status yes
      set -g theme_display_git_untracked yes
    '';
  };
  
  home.sessionPath = [
    # Add the user's Nix profile path.
    # Using ${config.home.profileDirectory} is more robust than a hardcoded path.
    "${config.home.profileDirectory}/bin"
  ];
}
