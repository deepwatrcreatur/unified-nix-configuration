{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../default.nix
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  home.packages = with pkgs; [
  ];

  home.stateVersion = "24.11";
}
