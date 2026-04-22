{ config, lib, pkgs, ... }:

let
  cfg = config.programs.cass-session-search;
  cassPackage = pkgs.writeShellApplication {
    name = "cass-session-search";
    runtimeInputs = [ pkgs.ripgrep ];
    text = builtins.readFile ../../../scripts/cass-session-search.sh;
  };
in
{
  options.programs.cass-session-search = {
    enable = lib.mkEnableOption "CASS-style search over local coding-agent sessions";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cassPackage ];
  };
}
