# outputs/hackintosh.nix
{ helpers, ... }:
(helpers.mkDarwinOutput {
  name = "hackintosh";
  system = "x86_64-darwin";
  hostPath = ../hosts/hackintosh;
  username = "deepwatrcreatur";
})
