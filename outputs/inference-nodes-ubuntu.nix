# outputs/inference-nodes-ubuntu.nix - Ubuntu Inference Node Home Manager Configurations
{ helpers, ... }:
{
  # Generic inference node configuration
  homeConfigurations.deepwatrcreatur-inference-node = helpers.mkHomeConfig {
    system = "x86_64-linux";
    userPath = ../users/deepwatrcreatur/hosts/inference-node;
  };

  homeConfigurations.root-inference-node = helpers.mkHomeConfig {
    system = "x86_64-linux";
    userPath = ../users/root/hosts/inference-node;
  };
}