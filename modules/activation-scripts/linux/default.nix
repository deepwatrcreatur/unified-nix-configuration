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
    # Individual script enable options are defined in their respective modules
  };

  # No need to set defaults here - each module handles its own enable option
}
