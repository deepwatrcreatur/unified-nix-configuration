# outputs/macminim4.nix
{ helpers, ... }:
(helpers.mkDarwinOutput {
  name = "macminim4";
  system = "aarch64-darwin";
  hostPath = ../hosts/macminim4;
  username = "deepwatrcreatur";
})
