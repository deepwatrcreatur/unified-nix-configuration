{ lib, ... }:
{
  options.myModules.caches = {
    enable = lib.mkEnableOption "Enable shared cache configuration";

    enableAttic = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable local Attic cache (attic-cache).";
    };

    enableNixCi = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable nix-ci.com cache when credentials are available.";
    };
  };

  config = lib.mkIf config.myModules.caches.enable {
    # Nothing here: behavior is implemented in modules/common/nix-settings.nix
  };
}
