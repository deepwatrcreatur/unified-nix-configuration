# modules/just.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.just;
in
{
  # Define options for just configuration
  options.programs.just = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the just command runner and install it system-wide.";
    };
  };

  # Configuration
  config = lib.mkIf cfg.enable {
    # Install just
    environment.systemPackages = [ pkgs.just ];

  };
}
