{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.users.root.shell = pkgs.fish;

  # RustDesk user for remote desktop access
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    # Password will be set during first SSH access or via SOPS secrets
  };
}
