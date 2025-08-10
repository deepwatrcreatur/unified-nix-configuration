# outputs/_template-home.nix
# Template for new Home Manager configs - copy and rename this file
# Remove the underscore prefix when creating a real host config

{ helpers, ... }:
{
  homeConfigurations.my-new-home = helpers.mkHomeConfig {
    system = "x86_64-linux"; # or "aarch64-linux", "x86_64-darwin", "aarch64-darwin"
    userPath = ./users/username/hosts/my-new-home;
    
    # Optional: add extra modules
    # modules = [
    #   ({ config, pkgs, ... }: {
    #     # Custom configuration here
    #   })
    # ];
  };
}
