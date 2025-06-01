# modules/home-manager/cargo-binstall.nix
{ pkgs, ... }: # Remove 'lib' from arguments if not used elsewhere

let
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
