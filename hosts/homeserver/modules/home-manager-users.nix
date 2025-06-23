{ config, pkgs, lib, inputs, ... }:

let
  # Define shared packages to extend home.packages
  sharedPackages = with pkgs; [
    pinentry-curses
    links2
  ];
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; }; # This is good, passes 'inputs' down

    users.deepwatrcreatur = {
      imports = [
        ../../../users/deepwatrcreatur 
        ../../../users/deepwatrcreatur/hosts/macminim4 
        ../../../modules/home-manager
                                     
      ];
      home.packages = (config.home.packages or []) ++ sharedPackages ++ [        
      ];
    };

    users.root = {
      imports = [

        ../../../modules/home-manager # Ensure this doesn't try to load gnupg
      ];
      home.packages = (config.home.packages or []) ++ sharedPackages ++ [
      ];
    };
  };
}
