# modules/home-manager/bitwarden-cli.nix
{ config, pkgs, lib, inputs, bwSessionSecretPath ? null, ... }:
{
  home.packages = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
    bitwarden-cli
  ]);

  # Only configure environment if secret path is provided
  programs.bash.initExtra = lib.mkIf (bwSessionSecretPath != null) ''
    export BW_SESSION="$(cat ${bwSessionSecretPath})"
  '';

  programs.zsh.initExtra = lib.mkIf (bwSessionSecretPath != null) ''
    export BW_SESSION="$(cat ${bwSessionSecretPath})"
  '';

  programs.fish.interactiveShellInit = lib.mkIf (bwSessionSecretPath != null) ''
    set -gx BW_SESSION (cat ${bwSessionSecretPath})
  '';

  programs.nushell.extraConfig = lib.mkIf (bwSessionSecretPath != null) ''
    $env.BW_SESSION = (open ${bwSessionSecretPath} | str trim)
  '';
}
