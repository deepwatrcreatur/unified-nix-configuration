{ ... }:
{ lib, ... }:
let
  githubTokenFile = ../../secrets-agenix/github-token.age;
in
{
  age.secrets."github-token" = lib.mkIf (builtins.pathExists githubTokenFile) {
    file = githubTokenFile;
    path = "/run/secrets/github-token";
    owner = "deepwatrcreatur";
    mode = "0600";
  };
}
