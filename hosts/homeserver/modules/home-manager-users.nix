{ config, pkgs, lib, inputs, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    
    users.deepwatrcreatur = {
      imports = [
        ../../../users/deepwatrcreatur
        ../../../users/deepwatrcreatur/hosts/homeserver
        ../../../modules/home-manager
      ];
    };

    users.root = {
      imports = [
        ../../../users/root
        ../../../users/root/hosts/homeserver
        ../../../modules/home-manager
      ];
    };
  };
}
