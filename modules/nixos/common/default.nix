# modules/nixos/common/default.nix
# Common NixOS modules that should be imported by all NixOS hosts

{
  imports = [
    ./locale.nix
    ./nh.nix
    ./ssh-keys.nix
    ./sops.nix
  ];

  # Increase the file descriptor limit for the Nix daemon
  systemd.services.nix-daemon.serviceConfig.LimitNOFILE = 200000;
}