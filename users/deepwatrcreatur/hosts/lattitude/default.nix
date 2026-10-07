# users/deepwatrcreatur/hosts/lattitude/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../..
    ./justfile.nix
    ./nh.nix
    ./rbw.nix
    ../../../../modules/home-manager/git.nix
    ../../../../modules/home-manager/git-ssh-signing.nix
    ../../../../modules/home-manager/ssh-agent.nix
  ];

  home.packages = with pkgs; [
    vivaldi
    google-chrome
    firefox
    thunderbird
    rclone
    epiphany
    qutebrowser
  ];

  programs.bash.enable = true;
  programs.home-manager.enable = true;

  home.stateVersion = "26.05";
}
