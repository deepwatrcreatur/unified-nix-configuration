# ./hosts/homeserver/modules/sops.nix
{ config, lib, pkgs, ... }:

{
  # This is the central SOPS configuration for this host.
  sops = {
    # The age key needed to decrypt all secrets for this host.
    age.keyFile = lib.mkForce "/etc/nixos/secrets/age-key.txt";
    validateSopsFiles = false;
    secrets = {
      API_KEY = {
        # Path is relative to this sops.nix file.
        sopsFile = ../secrets/cloudflare-secrets.yaml;
        # The format is needed if the secret is not a simple string.
        format = "yaml";
      };
    };
  };
}
