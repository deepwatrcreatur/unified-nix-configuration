{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../default.nix
    ./nh.nix
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  home.packages = with pkgs; [
  ];

  home.stateVersion = "25.05";
}
