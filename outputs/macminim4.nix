# outputs/macminim4.nix
{ helpers, ... }:
{
  darwinConfigurations.macminim4 = helpers.mkDarwinSystem {
    system = "aarch64-darwin";
    hostPath = ../hosts/macminim4;
    username = "deepwatrcreatur";
  };
}
