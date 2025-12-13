# modules/activation-scripts/default.nix
# Main activation scripts bundle module with enable/disable options

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.activation-scripts;
in
{
  # Import both platform modules unconditionally - they will use mkIf internally
  # to only apply their configs on the appropriate platform
  imports = [
    ./linux
  ];

  options.custom.activation-scripts = {
    enable = lib.mkEnableOption "All activation scripts bundle" // {
      default = true;
      description = "Enable/disable all activation scripts. Individual scripts can be controlled separately.";
    };

    linux = {
      enable = lib.mkEnableOption "Linux activation scripts bundle" // {
        default = true;
        description = "Enable/disable all Linux activation scripts.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable platform-specific bundles when main bundle is enabled
    custom.activation-scripts.linux.enable = lib.mkDefault cfg.linux.enable;
  };
}
