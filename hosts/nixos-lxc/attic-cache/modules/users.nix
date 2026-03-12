{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.users.root.shell = pkgs.fish;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIB4ELcnxIV0zujIJ4EPubU5nkKPV7G8pZ3tDDjZ6pXI deepwatrcreatur@gmail.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbbK4WrxQjuHiDKSYrKmhVY2hJCn+QWuTaNIqfcsedu root@gateway" # For remote builds
  ];

  # Regular user deepwatrcreatur
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    home = "/home/deepwatrcreatur";
    description = "Deep Water Creature";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIB4ELcnxIV0zujIJ4EPubU5nkKPV7G8pZ3tDDjZ6pXI deepwatrcreatur@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbbK4WrxQjuHiDKSYrKmhVY2hJCn+QWuTaNIqfcsedu root@gateway" # For remote builds
    ];
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

  users.groups.nixbuilder = { };
}
