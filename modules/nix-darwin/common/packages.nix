# modules/nix-darwin/common/packages.nix
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  environment.systemPackages =
    (with pkgs; [
      watch
    ])
    ++ (with inputs.nix-darwin.packages.${pkgs.stdenv.hostPlatform.system}; [
      darwin-option
      darwin-rebuild
      darwin-version
      darwin-uninstaller
    ]);
}
