# den/aspects/desktop-network-shares.nix
# Strata with network browsing: GVfs provides the smb://, sftp:// and network:// backends,
# and Avahi provides the mDNS discovery that populates network://.
{ ... }:
{ pkgs, ... }:
{
  programs.strata.enable = true;

  services.gvfs.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # gvfsd-network spawns wsdd from PATH to discover Windows hosts over WS-Discovery.
  environment.systemPackages = [ pkgs.wsdd ];
}
