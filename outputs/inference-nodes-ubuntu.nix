# outputs/inference-nodes-ubuntu.nix - Ubuntu Inference Node Home Manager Configurations
{ helpers, ... }:
{
  # Generic inference node configuration
  homeConfigurations.deepwatrcreatur-inference-node = helpers.mkHomeConfig {
    targetSystem = "x86_64-linux";
    hostName = "deepwatrcreatur-inference-node";
    userPath = ../users/deepwatrcreatur/hosts/inference-node;
  };

  homeConfigurations.root-inference-node = helpers.mkHomeConfig {
    targetSystem = "x86_64-linux";
    hostName = "root-inference-node";
    userPath = ../users/root/hosts/inference-node;
  };
}
