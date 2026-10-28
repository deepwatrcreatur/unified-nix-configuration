# den/aspects/declarative-runtime.nix
# Declarative NixOS service runtime configuration via paired OpenTofu providers
# (https://github.com/applicative-systems/declarative-runtime)
{ ... }:
{ inputs, pkgs, ... }:
{
  imports = [
    inputs.declarative-runtime.nixosModules.default
  ];

  # declarative-runtime pins the keycloak provider schema to 5.9.0.
  # Ensure the host's terraform-providers.keycloak_keycloak matches the schema version.
  nixpkgs.overlays = [
    (final: prev: {
      terraform-providers = prev.terraform-providers // {
        keycloak_keycloak =
          inputs.declarative-runtime.inputs.nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}.terraform-providers.keycloak_keycloak;
      };
    })
  ];

  # Make OpenTofu available in the host environment for operator state inspection and CLI workflows
  environment.systemPackages = [
    pkgs.opentofu
  ];
}
