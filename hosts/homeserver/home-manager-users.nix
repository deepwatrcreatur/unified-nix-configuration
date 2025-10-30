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
        ../../users/deepwatrcreatur 
        ../../users/deepwatrcreatur/hosts/homeserver
        ../../modules/home-manager
                                     
      ];
      home.packages = (config.home.packages or []) ++ sharedPackages ++ [        
      ];
    };

  };

  # Systemd service for Home Manager
  systemd.services.home-manager-deepwatrcreatur = {
    description = "Home Manager activation for deepwatrcreatur";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.home-manager}/bin/home-manager switch --flake .#deepwatrcreatur@homeserver";
      User = "deepwatrcreatur";
    };
  };
  
}
