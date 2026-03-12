# modules/home-manager/common/dmux.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.dmux;

  # Derivation for the dmux package
  dmux-pkg = pkgs.rustPlatform.buildRustPackage rec {
    pname = "dmux";
    version = "0.1.0"; # From Cargo.toml

    src = pkgs.fetchFromGitHub {
      owner = "standardagents";
      repo = "dmux";
      rev = "main"; # Using main as there are no release tags
      # The user will need to replace this with the correct hash after the first build fails.
      sha256 = "0000000000000000000000000000000000000000000000000000";
    };

    # The user will need to replace this with the correct hash after the first build fails.
    cargoSha256 = "0000000000000000000000000000000000000000000000000000";

    meta = {
      description = "A command-line tool for multi-agent workflows";
      homepage = "https://github.com/standardagents/dmux";
      license = licenses.mit; # Assuming MIT from common practice, check repo if needed
    };
  };

in
{
  options.programs.dmux = {
    enable = mkEnableOption "dmux - a multi-agent workflow tool";
  };

  config = mkIf cfg.enable {
    home.packages = [ dmux-pkg ];
  };
}
