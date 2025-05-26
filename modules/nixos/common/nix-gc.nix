{ config, lib, pkgs, ... }:

{
  # Only applies to NixOS, not nix-darwin
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 10d";
  };
}

