{ lib, ... }:

{
  # Periodic TRIM for SSD-backed storage.
  # Harmless if discard isn't supported (it becomes a no-op).
  services.fstrim = {
    enable = lib.mkDefault true;
    interval = lib.mkDefault "weekly";
  };
}
