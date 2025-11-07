{ config, pkgs, lib, ... }:

{
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  sops.secrets."atuin-key" = {
    sopsFile = ../../../secrets/atuin-key.enc;
    key = "atuin_key";
    path = "${config.home.homeDirectory}/.config/atuin/key.json";
  };
}