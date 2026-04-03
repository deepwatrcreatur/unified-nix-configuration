{ inputs, ... }:

{
  imports = [ inputs.nix-attic-infra.homeManagerModules.attic-client-darwin ];
}
