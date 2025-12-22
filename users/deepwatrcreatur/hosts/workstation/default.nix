{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../../default.nix
    ./nh.nix

    ../../../../modules/home-manager
    ../../../../modules/home-manager/ghostty
    ../../../../modules/home-manager/just.nix
    ../../../../modules/home-manager/just-nixos.nix
    #../../../../modules/home-manager/gnome.nix
    ../../../../modules/home-manager/zed.nix
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  home.packages = with pkgs; [
    bitwarden-desktop
    ffmpeg
    gitkraken
    deskflow
    mailspring
    megacmd
    obsidian
    obsidian-export
    virt-viewer
  ];

  programs.firefox = {
    enable = true;
  };

  programs.google-chrome = {
    enable = true;
  };

  # Tmux-enhanced is enabled by default via common modules

  # Enable enhanced yazelix with custom improvements (commented out due to nixpkgs issue)
# programs.yazelix-enhanced = {
#   enable = true;
#   enableShellIntegration = true;
#   editor = "hx";
#   extraPackages = with pkgs; [
#     eza
#     fd
#     ripgrep
#     fzf
#     zoxide
#   ];
#   customKeybinds = ''
#     [manager.prepend_keymap]
#     on = [ "g", "h" ]
#     run = "cd ~"
#     desc = "Go to home directory"

#     [manager.prepend_keymap]
#     on = [g", "c" ]
#     run = "cd ~/.config"
#     desc = "Go to config directory"

#     [manager.prepend_keymap]
#     on = [g", "d" ]
#     run = "cd ~/Downloads"
#     desc = "Go to downloads"

#     [manager.prepend_keymap]
#     on = [g", "c" ]
#     run = "search fd"
#     desc = "Search files with fd"
#     [manager.prepend_keymap]
#     on = [C-s" ]
#     run = "search rg"
#     desc = "Search content with ripgrep"
#   '';
#   };



  # Justfile now managed by home-manager just modules

  home.file.".config/deskflow/deskflow.conf".text = ''
    clipboardSharing = true
  '';

  # Deskflow server service
  systemd.user.services.deskflow = {
    Unit = {
      Description = "Deskflow Server";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.deskflow}/bin/deskflow server --config ${config.home.homeDirectory}/.config/deskflow/deskflow.conf
      '';
      Restart = "on-failure";
      RestartSec = "5";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  home.stateVersion = "24.11";
}
