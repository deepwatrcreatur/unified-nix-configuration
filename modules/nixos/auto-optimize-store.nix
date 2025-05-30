# modules/nixos/auto-optimise-store.nix
{ config, lib, pkgs, ... }:

{
  nix.settings.auto-optimise-store = true;
}

