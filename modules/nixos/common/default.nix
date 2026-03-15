# modules/nixos/common/default.nix
# Common NixOS modules that should be imported by all NixOS hosts

{
  imports = [
    ../host-options.nix  # Declarative host configuration options
    ./home-manager.nix
    ./locale.nix
    ./nh.nix
    ./ssh-keys.nix
    ./agenix.nix
    ./fstrim.nix
    ./git-ssh.nix
    # ../../activation-scripts
  ];
}
