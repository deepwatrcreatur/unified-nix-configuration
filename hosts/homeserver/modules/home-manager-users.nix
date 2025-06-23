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
        (import ./users/deepwatrcreatur {
          inherit pkgs inputs lib; 
          sopsLib = config.lib.sops;
        })
        (import ./users/deepwatrcreatur/hosts/macminim4 {
          inherit pkgs inputs lib;
          sopsLib = config.lib.sops; 
        })
        ../../../modules/home-manager # This might import other HM modules for deepwatrcreatur
                                     # Ensure this (or anything it imports) doesn't try to load gnupgain.
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
