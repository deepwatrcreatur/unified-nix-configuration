# outputs/inference-nodes-ubuntu.nix - Ubuntu Inference Node Home Manager Configurations
{ helpers, ... }:
{
  # Inference Node 1 - deepwatrcreatur user
  homeConfigurations.deepwatrcreatur-inference-node1 = helpers.mkHomeConfig {
    system = "x86_64-linux";
    userPath = ../users/deepwatrcreatur/hosts/inference-node1;
  };

  # Inference Node 1 - root user
  homeConfigurations.root-inference-node1 = helpers.mkHomeConfig {
    system = "x86_64-linux";
    userPath = ../users/root/hosts/inference-node1;
  };

  # Inference Node 2 - deepwatrcreatur user
  homeConfigurations.deepwatrcreatur-inference-node2 = helpers.mkHomeConfig {
    system = "x86_64-linux";
    userPath = ../users/deepwatrcreatur/hosts/inference-node2;
  };

  # Inference Node 2 - root user
  homeConfigurations.root-inference-node2 = helpers.mkHomeConfig {
    system = "x86_64-linux";
    userPath = ../users/root/hosts/inference-node2;
  };

  # Inference Node 3 - deepwatrcreatur user
  homeConfigurations.deepwatrcreatur-inference-node3 = helpers.mkHomeConfig {
    system = "x86_64-linux";
    userPath = ../users/deepwatrcreatur/hosts/inference-node3;
  };

  # Inference Node 3 - root user
  homeConfigurations.root-inference-node3 = helpers.mkHomeConfig {
    system = "x86_64-linux";
    userPath = ../users/root/hosts/inference-node3;
  };

  # Generic inference node configuration (for new nodes)
  homeConfigurations.deepwatrcreatur-inference-node = helpers.mkHomeConfig {
    system = "x86_64-linux";
    userPath = ../users/deepwatrcreatur/hosts/inference-node;
  };

  homeConfigurations.root-inference-node = helpers.mkHomeConfig {
    system = "x86_64-linux";
    userPath = ../users/root/hosts/inference-node;
  };
}