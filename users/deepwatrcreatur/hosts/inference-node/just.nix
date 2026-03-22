# users/deepwatrcreatur/hosts/inference-node/just.nix
{
  my.just = {
    backend = "home-manager";
    flakeTarget = "deepwatrcreatur-inference-node";
  };
}
