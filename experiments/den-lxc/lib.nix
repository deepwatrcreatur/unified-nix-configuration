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
      aspectsList,
    }:
    {
      imports =
        map
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
          aspectsList;
    };
}
