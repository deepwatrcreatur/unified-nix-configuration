# ~/.config/home-manager/home.nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ./git.nix
  ];

  home.stateVersion = "24.05";

  # Set the username and home directory for Home Manager
  home.username = "root";
  home.homeDirectory = "/root"; # Home directory for the root user

  # Add packages
  home.packages = [
    pkgs.htop
    pkgs.btop
    pkgs.bat
    pkgs.gh
    pkgs.git
    pkgs.helix
    pkgs.rsync
    pkgs.iperf3
    pkgs.lazygit
    pkgs.lsd
    pkgs.starship
  ];

  # Configure programs

  programs.bash.enable = true; # Example: enable bash integration

  programs.fish = {
    enable = true;

  shellInit = ''
    # Nix integration for Fish shell
    if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    end

    set -gx EDITOR hx
    set -gx VISUAL hx
  '';

    shellAliases = {
      ls = "lsd";
      ll = "lsd -l";
      la = "lsd -a";
      lla = "lsd -la";
      ".." = "cd ..";
      update = "home-manager switch --flake $HOME/proxmox-host-configuration/home-manager#${config.home.username}@$(hostname)";
    };
    plugins = [
      { name = "fzf"; src = pkgs.fishPlugins.fzf; }
      { name = "z"; src = pkgs.fishPlugins.z; }
      { name = "puffer"; src = pkgs.fishPlugins.puffer; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair; }
      { name = "grc"; src = pkgs.fishPlugins.grc; }
      { name = "bobthefish"; src = pkgs.fishPlugins.bobthefish; }
    ];
    interactiveShellInit = ''
      # Source Home Manager's environment (should be auto-generated)
      if test -e $HOME/.nix-profile/etc/profile.d/hm-session-vars.fish
        source $HOME/.nix-profile/etc/profile.d/hm-session-vars.fish
      end
      set -g theme_color_scheme solarized
      set -g theme_powerline_fonts no
      set -g theme_project_dir_length 1
      set -g theme_show_exit_status yes
      set -g theme_display_git_untracked yes
      starship init fish | source
    '';
  };
  
  # Let Home Manager manage itself if you want the `home-manager` command available
  programs.home-manager.enable = true;
}
