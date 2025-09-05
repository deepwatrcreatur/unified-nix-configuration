# outputs/nixos-lxc.nix
{ helpers, importAllModulesInDir, inputs, nixpkgsLib, systemSpecialArgs, homeManagerModuleArgs, commonOverlays, commonNixpkgsConfig, ... }:
{
  # LXC configuration without Determinate Nix for initial bootstrap
  nixosConfigurations.nixos_lxc_without_determinate = nixpkgsLib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = systemSpecialArgs;
    modules = [
      {
        nixpkgs.overlays = commonOverlays;
        nixpkgs.config = commonNixpkgsConfig;
      }
      inputs.sops-nix.nixosModules.sops
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.extraSpecialArgs = homeManagerModuleArgs;
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.sharedModules = [
          inputs.sops-nix.homeManagerModules.sops
          inputs.plasma-manager.homeManagerModules.plasma-manager
        ];
      }
      # NOTE: Excluded inputs.determinate.nixosModules.default for LXC compatibility
      ../modules
      ../hosts/nixos  # Base NixOS config
    ] ++ (importAllModulesInDir ../hosts/nixos_lxc/modules);
  };

  # LXC configuration with Determinate Nix for transition after bootstrap
  nixosConfigurations.nixos_lxc_with_determinate = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ../hosts/nixos;  # Base NixOS config
    modules = importAllModulesInDir ../hosts/nixos_lxc/modules;
  };
}
