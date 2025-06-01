# modules/home-manager/cargo-binstall.nix
{ pkgs, ... }:

let
  # Use pkgs.makeWrapper to create a wrapper for the cargo binary.
  # This is more robust for creating executable symlinks.
  myCargo = pkgs.makeWrapper "${pkgs.rustc}/bin/cargo" "$out/bin/cargo" {};

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
