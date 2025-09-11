# modules/nixos/common/default.nix
# Common NixOS modules that should be imported by all NixOS hosts

{
  imports = [
    ./locale.nix
    ./nh.nix
    ./ssh-keys.nix
  ];
}