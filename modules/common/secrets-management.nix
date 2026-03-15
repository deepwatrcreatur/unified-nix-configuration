{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Secrets management tools for all hosts
  # Provides tools for managing age-encrypted secrets with agenix
  environment.systemPackages = with pkgs; [
    age         # Modern encryption tool (reference implementation)
    rage        # Rust implementation of age (faster, used by agenix)
    agenix-cli  # Nix secrets management CLI
    ssh-to-age  # Convert SSH ed25519 keys to age keys
  ];
}
