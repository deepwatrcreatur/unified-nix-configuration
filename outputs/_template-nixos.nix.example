# outputs/_template-nixos.nix
# Template for new NixOS hosts - copy and rename this file
# Remove the underscore prefix when creating a real host config

{ helpers, importAllModulesInDir, ... }:
{
  nixosConfigurations.my-new-host = helpers.mkNixosSystem {
    system = "x86_64-linux"; # or "aarch64-linux"
    hostPath = ../hosts/my-new-host;
    
    # Optional: add modules from a directory
    # modules = importAllModulesInDir ./hosts/my-new-host/modules;
    
    # Optional: add extra modules inline
    # extraModules = [
    #   ({ config, pkgs, ... }: {
    #     # Custom configuration here
    #   })
    # ];
  };
}
