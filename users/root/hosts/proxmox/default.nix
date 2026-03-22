{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./justfile.nix
    ./nh.nix
    ./proxmox-shell-extra.nix
    ../../../../modules/home-manager/git.nix
    ../../../../modules/home-manager/gpg-cli.nix
    # Selectively import only essential modules to avoid activation issues
    ../../../../modules/home-manager/secrets-activation.nix
    ../../../../modules/home-manager/user-secrets.nix
    ../../../../modules/home-manager/common/nix-user-config.nix
    ../../../../modules/home-manager/common/attic-client.nix
    ../../../../modules/home-manager/common/fish.nix
    ../../../../modules/home-manager/common/starship.nix
    ../../../../modules/home-manager/common/atuin.nix
    ../../../../modules/home-manager/common/fnox.nix
    ../../../../modules/home-manager/common/bat.nix
    ../../../../modules/home-manager/common/tool-aliases.nix
  ];

  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.11";

  nix.package = pkgs.nix;

  home.packages = with pkgs; [
    proxmenux
  ];
  # Determinate Nix manages `/etc/nix/nix.conf`; we only add user extras.
  services.nix-user-config = {
    enable = true;
    netrcMachine = null;
    substituters = [
      "http://attic-cache:5001/cache-local"
      "https://cache.nix-ci.com"
      "https://cache.nixos.org"
    ];
    trustedPublicKeys = [
      "cache-local:63xryK76L6y/NphTP/iS63yiYqldoWvVlWI0N8rgvBw="
      "cache-local:GozZz7XFsUZ7xI5o/Q36JA/BFfjzONWOjiqC+zAhp2g="
      "cache-local:92faFQnuzuYUJ4ta3EYpqIaCMIZGenDoaPktsBucTe4="
      "nix-ci:g3xV5BDTLtIBZr/A00IU1x0EtKKlb7YLgBN2SgYgM6A="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    netrcEntries = [
      {
        machine = "attic-cache";
        passwordPath = "${config.home.homeDirectory}/.config/sops/attic-client-token";
        fnoxSecretName = "ATTIC_CLIENT_JWT_TOKEN";
      }
    ];
    netrcSnippetPaths = [
      "${config.home.homeDirectory}/.config/nix/nix-ci-netrc"
    ];
  };

  # Allow root to manage Home Manager
  programs.home-manager.enable = true;

  # Enable attic-client for binary cache access
  programs.attic-client.enable = true;

  # Prefer system or future agenix-provided tokens while keeping the existing
  # root SOPS secrets path as a compatibility fallback on Debian/Proxmox hosts.
  services.user-secrets = {
    enable = true;
    secretsPath = ../../secrets;
  };

}
