# outputs/omarhy.nix
{ helpers, ... }:
{
  homeConfigurations.root = helpers.mkHomeConfig {
    system = "x86_64-linux";
    userPath = ../users/root/hosts/omarchy;
  };
  homeConfigurations.deepwatrcreatur = helpers.mkHomeConfig {
    system = "x86_64-linux";
    userPath = ../users/deepwatrcreatur/hosts/omarchy;
  };
}
