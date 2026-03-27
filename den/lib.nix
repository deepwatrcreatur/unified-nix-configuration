{ lib }:

let
  aspects = import ./aspects { inherit lib; };
in
{
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
              aspect = aspects.${aspectName} or (throw "Unknown den-lxc aspect: ${aspectName}");
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

  # Borrowed from vic/den: select a value by hostname at eval time.
  # Usage: denLib.perHost { workstation = x; phoenix = y; } config.networking.hostName
  perHost = hostMap: hostName:
    hostMap.${hostName} or (throw "perHost: no entry for hostname '${hostName}'");
}
