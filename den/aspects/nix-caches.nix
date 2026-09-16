{ lib, config, ... }:
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

    isCacheServer = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this host runs the local Attic binary cache server (avoids circular substitution).";
    };
  };

  config = lib.mkIf config.myModules.caches.enable {
    # Nothing here: behavior is implemented in modules/common/nix-settings.nix
  };
}
