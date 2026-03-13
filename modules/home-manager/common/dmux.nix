# modules/home-manager/common/dmux.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.programs.dmux;
in
{
  options.programs.dmux = {
    enable = mkEnableOption "dmux - a multi-agent workflow tool";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.dmux-flake.packages.${pkgs.system}.default ];
  };
}
