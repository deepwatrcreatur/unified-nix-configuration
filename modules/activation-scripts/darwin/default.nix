# modules/activation-scripts/darwin/default.nix
# Darwin activation scripts bundle

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.activation-scripts.darwin;
  
  # Auto-import all Darwin activation script modules
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

  options.custom.activation-scripts.darwin = {
    enable = lib.mkEnableOption "Darwin activation scripts bundle" // {
      default = true;
      description = "Enable/disable all Darwin activation scripts. Individual scripts can be controlled separately.";
    };
    
    # Individual script options with defaults
    post-activation.enable = lib.mkEnableOption "Post-activation script" // { default = true; };
    extra-activation.enable = lib.mkEnableOption "Extra activation script" // { default = true; };
    nix-mount.enable = lib.mkEnableOption "Nix mount activation scripts" // { default = false; };
  };

  config = lib.mkIf cfg.enable {
    # Enable individual scripts when bundle is enabled
    custom.activation-scripts.darwin.post-activation.enable = lib.mkDefault cfg.post-activation.enable;
    custom.activation-scripts.darwin.extra-activation.enable = lib.mkDefault cfg.extra-activation.enable;
    custom.activation-scripts.darwin.nix-mount.enable = lib.mkDefault cfg.nix-mount.enable;
  };
}