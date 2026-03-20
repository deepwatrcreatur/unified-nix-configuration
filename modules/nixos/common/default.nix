# modules/nixos/common/default.nix
# Common NixOS modules that should be imported by all NixOS hosts

{
  imports = [
    ../host-options.nix  # Declarative host configuration options
    ./home-manager.nix
    ./locale.nix
    ./nh.nix
    ./ssh-keys.nix
    ./remote-builder-key.nix
    ./agenix-machine-identity.nix
    ./agenix.nix
    ./fstrim.nix
    ./git-ssh.nix
    ./zram.nix  # Zram compressed swap for desktops
    ./nix-ci-netrc.nix  # nix-ci.com cache authentication
    ../../common/secrets-management.nix  # age/agenix/rage/ssh-to-age tools
    # ../../activation-scripts
  ];
}
