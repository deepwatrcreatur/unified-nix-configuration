{
  helpers,
  nixpkgsLib,
  ...
}:
let
  framework = import ../experiments/den-lxc/framework.nix {
    inherit helpers nixpkgsLib;
  };

  inventory = import ../experiments/den-lxc/inventory;
in
helpers.mergeOutputs [
  (framework.mkNixosOutput (inventory.hosts.homeserver // { outputName = "homeserver-den"; }))
  (framework.mkNixosOutput (inventory.hosts.podman // { outputName = "podman-den"; }))
]
