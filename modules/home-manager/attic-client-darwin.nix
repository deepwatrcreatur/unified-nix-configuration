{ inputs, lib, ... }:

{
  imports = [ inputs.nix-attic-infra.homeManagerModules.attic-client-darwin ];

  programs.attic-client.enable = lib.mkDefault true;
  services.nix-user-config.enable = lib.mkDefault true;
}
