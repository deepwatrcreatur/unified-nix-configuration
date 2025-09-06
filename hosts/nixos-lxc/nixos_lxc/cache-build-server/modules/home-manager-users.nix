{ config, lib, pkgs, ... }:

{
  home-manager.users.deepwatrcreatur = {
    home.stateVersion = "24.11";
    
    # Import common home manager modules
    imports = [
      ../../../../../modules/home-manager/common
    ];
    
    # Build server specific home config
    home.packages = with pkgs; [
      # Additional user tools for build server
    ];
  };
}