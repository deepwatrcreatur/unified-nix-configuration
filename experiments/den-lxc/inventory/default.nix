{
  hosts = import ./hosts.nix;
  homes = import ./homes.nix;
  darwin = import ./darwin.nix;
  bootstrap = import ./bootstrap.nix;
}
