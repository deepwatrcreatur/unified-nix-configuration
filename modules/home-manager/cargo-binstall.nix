# modules/home-manager/cargo-binstall.nix
{ pkgs, ... }:

let
  # Create a derivation that provides a 'cargo' binary which points to
  # the cargo from pkgs.rustc. This ensures 'cargo' is in your path directly.
  myCargo = pkgs.runCommand "my-cargo-bin" {} ''
    mkdir -p $out/bin
    ln -s ${pkgs.rustc}/bin/cargo $out/bin/cargo
  '';

in
{
  home.packages = [
    myCargo # This now explicitly provides the `cargo` command
    pkgs.cargo-binstall
  ];

  home.sessionVariables = {
    PATH = "$HOME/.cargo/bin:$PATH";
  };
}
