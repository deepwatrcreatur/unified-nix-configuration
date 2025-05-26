{ config, pkgs, lib, inputs, ... }:

{
  # Ensure just and nh are installed for the user
  home-manager.users.deepwatrcreatur = {
    home.packages = [ pkgs.just inputs.nh.packages.aarch64-darwin.default ];

    # Reference the external justfile in the same directory
    home.file.".justfile".source = ./justfile;
  };
}
