# outputs/cache-build-server.nix - NixOS Build Server LXC Container
{ helpers, importAllModulesInDir, inputs, nixpkgsLib, systemSpecialArgs, homeManagerModuleArgs, commonOverlays, commonNixpkgsConfig, ... }:
{
  # LXC configuration without standard helpers - following nixos_lxc_without_determinate pattern
  nixosConfigurations.cache-build-server = nixpkgsLib.nixosSystem {
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
        ];
      }
      inputs.determinate.nixosModules.default
      ../modules/nixos/lxc-modules.nix  # Use LXC-specific modules instead of regular ones
      ../hosts/nixos  # Base NixOS config
    ] ++ [
      ../hosts/nixos-lxc/nixos_lxc/cache-build-server/modules/configuration.nix
      # Keep working nixos_lxc modules for now
    ] ++ (importAllModulesInDir ../hosts/nixos-lxc/nixos_lxc/modules);
  };
}