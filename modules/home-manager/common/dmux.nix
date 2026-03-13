# modules/home-manager/common/dmux.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.dmux;
  dmux-pkg = import ../../pkgs/dmux { inherit pkgs lib; };

in
{
  options.programs.dmux = {
    enable = mkEnableOption "dmux - a multi-agent workflow tool";
  };

  config = mkIf cfg.enable {
    home.packages = [ dmux-pkg ];
  };
}
