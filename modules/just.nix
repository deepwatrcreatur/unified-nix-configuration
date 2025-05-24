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
    extraJustfile = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional content to append to /etc/justfile.";
    };
  };

  # Configuration
  config = lib.mkIf cfg.enable {
    # Install just
    environment.systemPackages = [ pkgs.just ];

    # Default justfile (can be overridden by host-specific configs)
    environment.etc."justfile".text = ''
      # Default justfile for shared commands
      # Add shared recipes here
      ${cfg.extraJustfile}
    '';
  };
}
