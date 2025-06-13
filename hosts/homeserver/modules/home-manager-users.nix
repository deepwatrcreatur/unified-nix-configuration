{ config, pkgs, lib, inputs, ... }:

let
  # Define shared packages to extend home.packages
  sharedPackages = with pkgs; [
    links2
  ];
in
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
      home.packages = (config.home.packages or []) ++ sharedPackages ++ [

      ];
    };

    users.root = {
      imports = [
        ../../../users/root
        ../../../users/root/hosts/homeserver
        ../../../modules/home-manager
      ];
      home.packages = (config.home.packages or []) ++ sharedPackages ++ [
        
      ];
    };
  };
}
