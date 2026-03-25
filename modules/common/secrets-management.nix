{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # Secrets management tools for all hosts
  # Provides tools for managing age-encrypted secrets with agenix
  #
  # USAGE: To edit/create secrets, use the agenix wrapper script:
  #   agenix-edit secrets-agenix/my-secret.age
  #
  # This wraps `nix run github:ryantm/agenix` which is compatible with our secrets.nix format.
  # Do NOT use the `agenix` command directly - that's agenix-cli which uses a different format.
  environment.systemPackages = with pkgs; [
    age         # Modern encryption tool (reference implementation)
    rage        # Rust implementation of age (faster, used by agenix)
    ssh-to-age  # Convert SSH ed25519 keys to age keys

    # Wrapper script for editing secrets with the correct agenix version
    (writeShellScriptBin "agenix-edit" ''
      # Wrapper for ryantm/agenix that's compatible with our secrets.nix format
      # Usage: agenix-edit secrets-agenix/my-secret.age
      exec nix run github:ryantm/agenix -- -e "$@"
    '')
  ];
}
