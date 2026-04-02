{ lib }:

let
  aspects = import ./aspects { inherit lib; };
  inventoryHosts = import ./inventory/hosts.nix;
in
rec {
  mkHostModule =
    {
      name,
      primaryUser ? "deepwatrcreatur",
      extraGroups ? [ "wheel" ],
      primaryUserImports ? [ ],
      rootImports ? [ ],
      extraImports ? [ ],
      aspectsList,
    }:
    {
      imports =
        (map
          (
            aspectName:
            let
              aspect = aspects.${aspectName} or (throw "Unknown den aspect: ${aspectName}");
            in
            aspect {
              inherit
                name
                primaryUser
                extraGroups
                primaryUserImports
                rootImports
                ;
            }
          )
          aspectsList) ++ extraImports;
    };

  mkInventoryHostModule =
    {
      name,
      ...
    }@args:
    let
      inventoryEntry =
        inventoryHosts.${name}
        or (throw "mkInventoryHostModule: unknown inventory host '${name}'");
      inventoryAspects =
        inventoryEntry.aspectsList
        or (throw "mkInventoryHostModule: host '${name}' has no aspectsList in den/inventory/hosts.nix");
    in
    {
      imports = (mkHostModule ((builtins.removeAttrs args [ "name" ]) // {
        inherit name;
        aspectsList = inventoryAspects;
      })).imports;
    };

  # Borrowed from vic/den: select a value by hostname at eval time.
  # Usage: denLib.perHost { workstation = x; phoenix = y; } config.networking.hostName
  perHost = hostMap: hostName:
    hostMap.${hostName} or (throw "perHost: no entry for hostname '${hostName}'");
}
