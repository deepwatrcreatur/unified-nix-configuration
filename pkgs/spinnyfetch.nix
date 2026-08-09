# pkgs/spinnyfetch.nix
# spinnyfetch - system-info fetcher with a spinning 3D logo by canavan-a
{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "spinnyfetch";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "canavan-a";
    repo = "spinnyfetch";
    rev = "e236e806e055a271b8167f8ee579d032318a3b18";
    hash = "sha256-68vHylr4wEZIF1/s4d4xDjnnJ1pNlEMZOojsTQjJJsc=";
  };

  vendorHash = "sha256-CJ33GAE7d87w7Ld1hTcjuz34gpqdagEOWx7ziCCAywQ=";

  meta = with lib; {
    description = "A NixOS system-info fetcher with a spinning 3D Nix logo";
    homepage = "https://github.com/canavan-a/spinnyfetch";
    mainProgram = "spinnyfetch";
  };
}
