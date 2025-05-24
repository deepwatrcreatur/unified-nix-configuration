# hosts/macminim4/just.nix
{ config, pkgs, lib, ... }:

{
  # Override the default justfile for macminim4
  environment.etc."justfile".text = ''
    update:
      darwin-rebuild switch --flake /Volumes/Work/unified-nix-configuration#${config.networking.hostName}
  '';
}
