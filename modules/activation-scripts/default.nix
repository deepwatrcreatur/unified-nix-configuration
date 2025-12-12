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
  imports = [
    # Only import Darwin modules on Darwin systems
    (lib.mkIf pkgs.stdenv.isDarwin ./darwin)
    # Only import Linux modules on Linux systems  
    (lib.mkIf pkgs.stdenv.isLinux ./linux)
  ];

  options.custom.activation-scripts = {
    enable = lib.mkEnableOption "All activation scripts bundle" // {
      default = true;
      description = "Enable/disable all activation scripts. Individual scripts can be controlled separately.";
    };
    
    darwin = {
      enable = lib.mkEnableOption "Darwin activation scripts bundle" // {
        default = pkgs.stdenv.isDarwin;
        description = "Enable/disable all Darwin activation scripts.";
      };
    };
    
    linux = {
      enable = lib.mkEnableOption "Linux activation scripts bundle" // {
        default = pkgs.stdenv.isLinux;
        description = "Enable/disable all Linux activation scripts.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable platform-specific bundles when main bundle is enabled
    custom.activation-scripts.darwin.enable = lib.mkDefault (pkgs.stdenv.isDarwin && cfg.darwin.enable);
    custom.activation-scripts.linux.enable = lib.mkDefault (pkgs.stdenv.isLinux && cfg.linux.enable);
  };
}