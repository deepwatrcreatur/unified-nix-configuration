# modules/home-manager/bitwarden-cli.nix

{ config, pkgs, lib, inputs, ... }:

{
  home.packages = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
    bitwarden-cli
  ]);

  sops = {
    secrets."BW_SESSION" = {
      sopsFile = ../../users/deepwatrcreatur/secrets/bitwarden.yaml.enc;
      format = "yaml";
    };
  };

  home.sessionVariables = {
    BW_SESSION = "$(cat ${config.sops.secrets.BW_SESSION.path})";
  };
}