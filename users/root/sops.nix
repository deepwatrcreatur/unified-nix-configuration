{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # imports = [
  #   inputs.sops-nix.homeManagerModules.sops
  # ];

  home.packages = with pkgs; [
    sops
  ];

  # Use the system-wide age key provided by the NixOS configuration
  # sops.age.keyFile = "/var/lib/sops/age/keys.txt";
  # sops.gnupg.home = "${config.home.homeDirectory}/.gnupg";

  home.file."${config.xdg.configHome}/sops/.sops.yaml" = {
    source = ./secrets/sops.yaml;
    force = true;
  };

  # Let sops-nix manage the decryption of these secrets automatically.
  # sops.secrets."github-token-root" = {
  #   sopsFile = ./secrets/github-token.txt.enc;
  #   format = "binary";
  #   # sops-nix will place the decrypted file at a path available via
  #   # config.sops.secrets."github-token-root".path
  # };

  # Set the GITHUB_TOKEN environment variable in fish shell
  # home.file.".config/fish/conf.d/github-token.fish".text = ''
  #   set -x GITHUB_TOKEN (cat ${config.sops.secrets."github-token-root".path})
  # '';
}
