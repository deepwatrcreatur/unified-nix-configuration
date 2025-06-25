{ config, pkgs, ... }:
{
  imports = [
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/rename.nix
    ../../modules/home-manager/zoxide.nix
    ./sops.nix
  ];

  home.username = "deepwatrcreatur";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];

  #programs.zoxide = {
  #  enable = true;
  #  enableBashIntegration = true;
  #  enableZshIntegration = true;
  #  enableFishIntegration = true;
  #  enableNushellIntegration = true;
  #};
}
