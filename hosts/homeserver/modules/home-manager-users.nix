{ config, pkgs, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.deepwatrcreatur = {
      imports = [
        ../../../users/deepwatrcreatur
        ../../../users/deepwatrcreatur/hosts/homeserver.nix
        ../../../modules/home-manager
      ];
    };
    users.root = {
      imports = [
        ../../../users/root/hosts/homeserver/default.nix
        ../../../modules/home-manager
      ];
    };
  };
}
