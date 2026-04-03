{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.programs.attic-client;
  atticCache = import ../../../lib/attic-cache.nix;
  defaultTokenPath = "${config.home.homeDirectory}/.config/sops/attic-client-token";
  defaultServers = {
    ${atticCache.serverName} = {
      endpoint = atticCache.serverEndpoint;
      tokenPath = defaultTokenPath;
      aliases = [ "cache" ];
    };
    "${atticCache.serverName}-local" = {
      endpoint = atticCache.serverEndpoint;
      tokenPath = defaultTokenPath;
      aliases = [ "local" ];
    };
  };
in
{
  imports = [ inputs.nix-attic-infra.homeManagerModules.attic-client ];

  config = lib.mkIf cfg.enable {
    programs.attic-client.servers = lib.mkDefault defaultServers;
  };
}
