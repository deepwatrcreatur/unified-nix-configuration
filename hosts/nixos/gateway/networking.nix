# Gateway-specific network defaults layered on top of nix-router-optimized's
# reusable router-networking module.
{
  ...
}:

{
  networking.hostName = "gateway";
  networking.domain = "deepwatercreature.com";

  # Disable systemd-resolved, use Technitium DNS directly
  services.resolved.enable = false;

  # DNS configuration - with fallback if Technitium is unavailable
  networking.nameservers = [
    "127.0.0.1"
    "1.1.1.1"
    "8.8.8.8"
  ];

  # Create static resolv.conf with our nameservers and search domain
  environment.etc."resolv.conf".text = ''
    search deepwatercreature.com
    nameserver 127.0.0.1
    nameserver 1.1.1.1
    nameserver 8.8.8.8
  '';

  # NAT is handled by nftables (see nftables.nix)
  networking.nat.enable = false;
}
