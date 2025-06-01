# modules/home-manager/cargo-binstall.nix
{ pkgs, lib, ... }: # Make sure 'lib' is available here

let
  # Use lib.makeWrapper to create a wrapper for the cargo binary.
  # This is the most robust way to ensure it's a function.
  myCargo = lib.makeWrapper "${pkgs.rustc}/bin/cargo" "$out/bin/cargo" {};

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
