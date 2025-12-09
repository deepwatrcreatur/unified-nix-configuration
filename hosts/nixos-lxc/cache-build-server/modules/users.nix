{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.users.root.shell = pkgs.fish;

  # Build user for remote builds
  users.users.nixbuilder = {
    isSystemUser = true;
    group = "nixbuilder";
    home = "/var/lib/nixbuilder";
    createHome = true;
    shell = pkgs.bash;
    # SSH keys will be managed via SOPS if needed
  };

  users.groups.nixbuilder = { };
}
