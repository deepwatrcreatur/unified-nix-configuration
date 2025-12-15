# modules/home-manager/common/navigation-aliases.nix
# Directory navigation and movement aliases
{
  config,
  lib,
  ...
}:
let
  # Navigation and directory movement aliases
  navigationAliases = {
    # Basic navigation
    ".." = "cd ..";

    # Extended navigation (optional - can be added if desired)
    # "..." = "cd ../..";
    # "...." = "cd ../../..";
    # "....." = "cd ../../../..";
  };
in
{
  options.custom.navigationAliases = {
    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = navigationAliases;
      description = "Directory navigation aliases";
      readOnly = true;
    };
  };

  
}
