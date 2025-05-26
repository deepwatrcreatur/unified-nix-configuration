{ config, pkgs, lib, inputs, ... }:

{
  # Ensure just and nh are installed for the user
  home-manager.users.deepwatrcreatur = {
    home.packages = [ pkgs.just ];

    # Reference the external justfile in the same directory
    home.file.".justfile".source = ./justfile;
  };
}
