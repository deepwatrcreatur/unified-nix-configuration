# modules/nixos/common/default.nix
# Common NixOS modules that should be imported by all NixOS hosts

{
  imports = [
    ./home-manager.nix
    ./locale.nix
    ./nh.nix
    ./ssh-keys.nix
    ./sops.nix
    ./fstrim.nix
    # ../../activation-scripts
  ];
}
