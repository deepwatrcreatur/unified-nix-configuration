# outputs/_template-darwin.nix
# Template for new Darwin hosts - copy and rename this file
# Remove the underscore prefix when creating a real host config

{ helpers, ... }:
{
  darwinConfigurations.my-new-mac = helpers.mkDarwinSystem {
    system = "aarch64-darwin"; # or "x86_64-darwin"
    hostPath = ./hosts/my-new-mac;
    username = "your-username";
    
    # Optional: add extra modules
    # modules = [
    #   ({ config, pkgs, ... }: {
    #     # Custom configuration here
    #   })
    # ];
  };
}
