{ config, lib, pkgs, ... }:

{
  users.users.root.shell = pkgs.fish;

  users.users.deepwatrcreatur = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "Anwer Khan";
    home = "/home/deepwatrcreatur";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    # SSH keys will be managed via SOPS if needed
  };

  # Build user for remote builds
  users.users.nixbuilder = {
    isSystemUser = true;
    group = "nixbuilder";
    home = "/var/lib/nixbuilder";
    createHome = true;
    shell = pkgs.bash;
    # SSH keys will be managed via SOPS if needed
  };
  
  users.groups.nixbuilder = {};
}
