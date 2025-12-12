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
  
  # Auto-import all activation script modules
  darwinDir = ./darwin;
  linuxDir = ./linux;
  
  darwinModules = builtins.readDir darwinDir;
  linuxModules = builtins.readDir linuxDir;
  
  darwinImports = lib.mapAttrsToList (name: type: 
    if type == "regular" && lib.hasSuffix ".nix" name 
    then darwinDir + "/${name}" 
    else if type == "directory" 
    then darwinDir + "/${name}/default.nix" 
    else null
  ) darwinModules;
  
  linuxImports = lib.mapAttrsToList (name: type: 
    if type == "regular" && lib.hasSuffix ".nix" name 
    then linuxDir + "/${name}" 
    else if type == "directory" 
    then linuxDir + "/${name}/default.nix" 
    else null
  ) linuxModules;
  
  # Filter out null values
  validDarwinImports = lib.filter (path: path != null) darwinImports;
  validLinuxImports = lib.filter (path: path != null) linuxImports;
in
{
  imports = 
    # Only import Darwin modules on Darwin systems
    (lib.optionals pkgs.stdenv.isDarwin validDarwinImports) ++
    # Only import Linux modules on Linux systems  
    (lib.optionals pkgs.stdenv.isLinux validLinuxImports);

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