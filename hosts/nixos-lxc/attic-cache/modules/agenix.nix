{ lib, ... }:

let
  # Define secret file paths for conditional loading
  atticClientTokenFile = ../../../../secrets-agenix/attic-client-token.age;
  atticServerTokenFile = ../../../../secrets-agenix/attic-server-token.age;
  atticJwtSecretFile = ../../../../secrets-agenix/attic-jwt-secret.age;
  githubTokenFile = ../../../../secrets-agenix/github-token.age;
  nixCiNetrcFile = ../../../../secrets-agenix/nix-ci-netrc.age;
in
{
  imports = [
    ../../../../modules/nixos/common/agenix-machine-identity.nix
  ];

  # Agenix configuration for attic-cache
  my.agenix.machineIdentity.enable = true;

  age.secrets."attic-client-token" = lib.mkIf (builtins.pathExists atticClientTokenFile) {
    file = atticClientTokenFile;
    path = "/run/secrets/attic-client-token";
    owner = "root";
    mode = "0400";
  };

  age.secrets."attic-server-token" = lib.mkIf (builtins.pathExists atticServerTokenFile) {
    file = atticServerTokenFile;
    path = "/run/secrets/attic-server-token";
    owner = "root";
    mode = "0400";
  };

  age.secrets."attic-jwt-secret" = lib.mkIf (builtins.pathExists atticJwtSecretFile) {
    file = atticJwtSecretFile;
    path = "/run/secrets/attic-jwt-secret";
    owner = "root";
    mode = "0400";
  };

  age.secrets."github-token" = lib.mkIf (builtins.pathExists githubTokenFile) {
    file = githubTokenFile;
    path = "/run/secrets/github-token";
    owner = "deepwatrcreatur";
    group = "users";
    mode = "0440";
  };

  age.secrets."nix-ci-netrc" = lib.mkIf (builtins.pathExists nixCiNetrcFile) {
    file = nixCiNetrcFile;
    path = "/run/secrets/nix-ci-netrc";
    owner = "root";
    mode = "0400";
  };
}
