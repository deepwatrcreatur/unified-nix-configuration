{ helpers, nixpkgsLib }:
{
  mkNixosOutput =
    {
      outputName ? name,
      name,
      system,
      hostPath,
      hostName ? outputName,
      modules ? [ ],
      extraModules ? [ ],
      isDesktop ? false,
      includeSnapd ? true,
      ...
    }:
    nixpkgsLib.setAttrByPath [ "nixosConfigurations" outputName ] (
      helpers.mkNixosSystem {
        inherit
          system
          hostPath
          hostName
          modules
          extraModules
          isDesktop
          includeSnapd
          ;
      }
    );

  mkDarwinOutput =
    {
      outputName ? name,
      name,
      system,
      hostPath,
      username,
      modules ? [ ],
      isDesktop ? true,
      ...
    }:
    nixpkgsLib.setAttrByPath [ "darwinConfigurations" outputName ] (
      helpers.mkDarwinSystem {
        inherit
          system
          hostPath
          username
          modules
          isDesktop
          ;
      }
    );

  mkHomeOutput =
    {
      outputName ? name,
      name,
      targetSystem,
      hostName ? name,
      userPath,
      modules ? [ ],
      isDesktop ? false,
      extraSpecialArgs ? { },
      ...
    }:
    nixpkgsLib.setAttrByPath [ "homeConfigurations" outputName ] (
      helpers.mkHomeConfig {
        inherit
          targetSystem
          hostName
          userPath
          modules
          isDesktop
          extraSpecialArgs
          ;
      }
    );
}
