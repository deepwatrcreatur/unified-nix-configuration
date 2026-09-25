# den/aspects/guest.nix
# Ephemeral guest specialization aspect.
# Provides an isolated, disposable guest account environment with a tmpfs-backed home,
# resource bounds, mesh network isolation, and autologin into the guest session.
{ ... }:
{ lib, ... }:
{
  imports = [
    ../../modules/nixos/specializations/guest.nix
  ];

  myModules.specializations.guest.enable = lib.mkDefault true;
}
