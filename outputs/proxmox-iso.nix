{
  inputs,
  nixpkgsLib,
  ...
}:
{
  nixosConfigurations.proxmox-iso = nixpkgsLib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ../hosts/nixos/proxmox-iso
    ];
  };
}
