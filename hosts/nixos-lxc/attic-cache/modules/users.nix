{
  config,
  lib,
  pkgs,
  ...
}:

let
  deepwatrcreaturStableKey = lib.strings.trim (builtins.readFile ../../../../ssh-keys/deepwatrcreatur-stable-identity.pub);
  deepwatrcreaturPhoenixKey = lib.strings.trim (builtins.readFile ../../../../ssh-keys/deepwatrcreatur-phoenix-identity.pub);
in
{
  # Login shell is bash; interactive sessions exec fish (see modules/nixos/fish-interactive-bash-login.nix)
  custom.fishInteractiveShell.users = [ "root" "deepwatrcreatur" ];
  users.users.root.openssh.authorizedKeys.keys = [
    deepwatrcreaturStableKey
    deepwatrcreaturPhoenixKey
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbX1mL3oZyEz1KhjEWww+k4RTXXeOJSqXWqu5N44ZAg root@router" # Legacy remote build key
  ];

  # Regular user deepwatrcreatur
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    home = "/home/deepwatrcreatur";
    description = "Deep Water Creature";
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      deepwatrcreaturStableKey
      deepwatrcreaturPhoenixKey
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbX1mL3oZyEz1KhjEWww+k4RTXXeOJSqXWqu5N44ZAg root@router" # Legacy remote build key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBZML6mOtZHRUmxNkIcv32q3kbBXMiOsQXyFzrWcUL4P nix-remote-builder" # For nix remote builder
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
