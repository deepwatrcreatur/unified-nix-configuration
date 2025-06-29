{ config, pkgs, ... }:

{
  # Install the Perl-based rename package
  home.packages = with pkgs; [
    rename
  ];
}

