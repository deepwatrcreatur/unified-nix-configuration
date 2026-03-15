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
    ../../common/secrets-management.nix  # age/agenix/rage/ssh-to-age tools
    # ../../activation-scripts
  ];
}
