# outputs/nixos-lxc.nix
{
  helpers,
  importAllModulesInDir,
  inputs,
  nixpkgsLib,
  systemSpecialArgs,
  homeManagerModuleArgs,
  commonOverlays,
  commonNixpkgsConfig,
  ...
}:
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
          # Exclude plasma-manager for LXC - not needed in headless container
        ];
      }
      # NOTE: Excluded inputs.determinate.nixosModules.default for LXC compatibility
      ../modules/nixos/lxc-modules.nix # Custom modules that exclude regular nix-settings
      ../hosts/nixos # Base NixOS config
    ]
    ++ (importAllModulesInDir ../hosts/nixos-lxc/nixos_lxc/modules);
  };

  # LXC configuration with Determinate Nix for transition after bootstrap
  nixosConfigurations.nixos_lxc_with_determinate = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ../hosts/nixos; # Base NixOS config
    modules = importAllModulesInDir ../hosts/nixos-lxc/nixos_lxc/modules;
  };
}
