{ config, pkgs, lib, ... }:
{
  home.file.".terminfo" = {
    source = ./terminfo; # Or use a relative path from this module
    recursive = true;
  };
}

