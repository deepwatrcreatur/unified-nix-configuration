{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = lib.mkForce "Anwer Khan";
        email = lib.mkForce "deepwatrcreatur@gmail.com";
      };
      signing.signByDefault = lib.mkForce true;
      gpg.format = lib.mkForce "ssh";
      "user".signingkey = lib.mkForce "~/.ssh/id_ed25519.pub";
    };
  };
}
