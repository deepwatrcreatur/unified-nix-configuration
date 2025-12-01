{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = lib.mkForce "root";
        email = lib.mkForce "deepwatrcreatur@gmail.com";
      };
      signing.signByDefault = lib.mkForce true;
    };
    signing = {
      key = "0xEF1502C27653693B";
    };
  };
}