# modules/home-manager/cargo-binstall.nix
{ pkgs, ... }:

let
  myCargo = pkgs.stdenv.mkDerivation {
    name = "cargo-wrapped";
    buildInputs = [ pkgs.makeWrapper ];
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp ${pkgs.rustc}/bin/cargo $out/bin/cargo
      wrapProgram $out/bin/cargo --prefix PATH : $out/bin
    '';
  };
in
{
  home.packages = [
    myCargo
    pkgs.cargo-binstall
  ];

  home.sessionVariables = {
    PATH = "$HOME/.cargo/bin:$PATH";
  };
}
