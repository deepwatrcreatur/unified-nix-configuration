# outputs/homeserver.nix
{ helpers, importAllModulesInDir, ... }:
{
  nixosConfigurations.homeserver = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ../hosts/nixos;  # Base NixOS config
    modules = importAllModulesInDir ../hosts/homeserver/modules;
    extraModules = 
      # Optional local secrets from original flake
      if builtins.pathExists /etc/nixos/local-secrets.nix
      then [ /etc/nixos/local-secrets.nix ]
      else [];
  };
}
