{ lib, ... }:

let
  # Define secret file paths for conditional loading
  atticClientTokenFile = ../../../../secrets-agenix/attic-client-token.age;
  atticServerTokenFile = ../../../../secrets-agenix/attic-server-token.age;
  atticJwtSecretFile = ../../../../secrets-agenix/attic-jwt-secret.age;
in
{
  # Agenix configuration for attic-cache
  age.identityPaths = [
    "/var/lib/agenix/machine-identity"
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/agenix 0700 root root -"
  ];

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
}
