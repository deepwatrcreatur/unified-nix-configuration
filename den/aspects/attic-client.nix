{ ... }:
{ lib, ... }:
let
  atticClientTokenFile = ../../secrets-agenix/attic-client-token.age;
in
{
  age.secrets."attic-client-token" = lib.mkIf (builtins.pathExists atticClientTokenFile) {
    file = atticClientTokenFile;
    path = "/run/secrets/attic-client-token";
    owner = "root";
    mode = "0400";
  };

  myModules.attic-client.enable = true;
}
