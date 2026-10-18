{ config, lib, pkgs, ... }:

let
  cfg = config.programs.iodyne;
in
{
  options.programs.iodyne = {
    enable = lib.mkEnableOption "iodyne - single-host disk IO, latency, topology, and health TUI";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.iodyne ];
  };
}
