{
  hackintosh = {
    kind = "darwin";
    name = "hackintosh";
    system = "x86_64-darwin";
    hostPath = ../../../hosts/hackintosh;
    username = "deepwatrcreatur";
    mode = "legacy";
  };

  macminim4 = {
    kind = "darwin";
    name = "macminim4";
    system = "aarch64-darwin";
    hostPath = ../../../hosts/macminim4;
    username = "deepwatrcreatur";
    mode = "legacy";
  };
}
