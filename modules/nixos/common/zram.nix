# modules/nixos/common/zram.nix
# Enable zram compressed swap for desktop systems
{ config, lib, ... }:

{
  config = lib.mkIf config.host.desktop.enable {
    zramSwap = {
      enable = true;
      # Use 50% of RAM for zram - with typical 2-3x compression ratio,
      # this effectively adds 100-150% of RAM as compressed swap
      memoryPercent = 50;
      # Use zstd for better compression ratio
      algorithm = "zstd";
      # Higher priority than disk swap (default is 5)
      priority = 100;
    };
  };
}
