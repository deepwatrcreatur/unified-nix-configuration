{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.programs.attic-client;
  atticCache = import ../../../lib/attic-cache.nix;
  atticServerType = lib.types.submodule {
    options = {
      endpoint = lib.mkOption {
        type = lib.types.str;
        description = "Attic server endpoint URL";
      };

      tokenPath = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.config/sops/attic-client-token";
        description = "Path to the token file used for this server.";
      };

      aliases = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Optional attic push/pull alias names for this server.";
      };
    };
  };
in
{
  imports = [ inputs.nix-attic-infra.homeManagerModules.attic-client ];

  options.programs.attic-client.defaultServers = lib.mkOption {
    type = lib.types.attrsOf atticServerType;
    default = {
      ${atticCache.serverName} = {
        endpoint = atticCache.serverEndpoint;
      };
      "${atticCache.serverName}-local" = {
        endpoint = atticCache.serverEndpoint;
      };
    };
    description = "Repository default Attic servers layered onto the upstream module.";
  };

  config = lib.mkIf cfg.enable {
    programs.attic-client.servers = lib.mkDefault cfg.defaultServers;
  };
}
