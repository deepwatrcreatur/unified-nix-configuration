# modules/activation-scripts/linux/default.nix
# Linux activation scripts bundle

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.activation-scripts.linux;
  
  # Auto-import all Linux activation script modules
  dir = ./.;
  modules = builtins.readDir dir;
  
  imports = lib.mapAttrsToList (name: type: 
    if type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
    then dir + "/${name}" 
    else if type == "directory" 
    then dir + "/${name}/default.nix" 
    else null
  ) modules;
  
  # Filter out null values and default.nix
  validImports = lib.filter (path: path != null) imports;
in
{
  imports = validImports;

  options.custom.activation-scripts.linux = {
    enable = lib.mkEnableOption "Linux activation scripts bundle" // {
      default = true;
      description = "Enable/disable all Linux activation scripts. Individual scripts can be controlled separately.";
    };
    
    # Individual script options with defaults
    homebrew.enable = lib.mkEnableOption "Homebrew activation script" // { default = false; };
    linuxbrew-system.enable = lib.mkEnableOption "Linuxbrew system setup script" // { default = false; };
    lxc-sh-wrapper.enable = lib.mkEnableOption "LXC /bin/sh wrapper script" // { default = false; };
  };

  config = lib.mkIf cfg.enable {
    # Enable individual scripts when bundle is enabled
    custom.activation-scripts.linux.homebrew.enable = lib.mkDefault cfg.homebrew.enable;
    custom.activation-scripts.linux.linuxbrew-system.enable = lib.mkDefault cfg.linuxbrew-system.enable;
    custom.activation-scripts.linux.lxc-sh-wrapper.enable = lib.mkDefault cfg.lxc-sh-wrapper.enable;
  };
}