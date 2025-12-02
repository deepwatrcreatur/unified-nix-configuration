# modules/home-manager/sops-root.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  home.packages = with pkgs; [
    sops
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  sops.secrets."github-token-root" = {
    sopsFile = ../../users/root/secrets/github-token.txt.enc;
    format = "binary";
  };

  home.file.".config/fish/conf.d/github-token.fish".text = ''
    set -x GITHUB_TOKEN (cat ${config.sops.secrets."github-token-root".path})
  '';
}
