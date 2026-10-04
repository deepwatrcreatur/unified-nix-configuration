# den/aspects/vpn-unlimited-client.nix
# VPN Unlimited (KeepSolid) client aspect for desktops.
# Integrates the official Flathub Flatpak (com.keepsolid.VpnUnlimited) with
# host NetworkManager via D-Bus for WireGuard tunnel establishment.
{ ... }:
{
  pkgs,
  lib,
  ...
}:
let
  vpnUnlimitedDesktopItem = pkgs.makeDesktopItem {
    name = "com.keepsolid.VpnUnlimited";
    desktopName = "VPN Unlimited";
    genericName = "VPN Client";
    comment = "KeepSolid VPN Unlimited Client";
    exec = "vpn-unlimited";
    icon = "com.keepsolid.VpnUnlimited";
    terminal = false;
    categories = [
      "Network"
      "Security"
    ];
  };

  vpnUnlimitedLauncher = pkgs.writeShellScriptBin "vpn-unlimited" ''
    if ! ${pkgs.flatpak}/bin/flatpak list --app | grep -q "com.keepsolid.VpnUnlimited"; then
      echo "Installing VPN Unlimited flatpak from Flathub..."
      ${pkgs.flatpak}/bin/flatpak install -y --or-update --noninteractive flathub com.keepsolid.VpnUnlimited
    fi
    exec ${pkgs.flatpak}/bin/flatpak run com.keepsolid.VpnUnlimited "$@"
  '';
in
{
  services.flatpak.enable = true;

  environment.systemPackages = [
    pkgs.wireguard-tools
    vpnUnlimitedLauncher
    vpnUnlimitedDesktopItem
  ];

  # Configure Flathub repository for Flatpak
  systemd.services.flatpak-repo-flathub = {
    description = "Configure Flathub repository for Flatpak";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo";
    };
  };

  # Automatically install or update VPN Unlimited Flatpak
  systemd.services.flatpak-install-vpn-unlimited = {
    description = "Install VPN Unlimited Flatpak from Flathub";
    wantedBy = [ "multi-user.target" ];
    after = [
      "flatpak-repo-flathub.service"
      "network-online.target"
    ];
    wants = [
      "flatpak-repo-flathub.service"
      "network-online.target"
    ];
    path = [ pkgs.flatpak ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.flatpak}/bin/flatpak install -y --or-update --noninteractive flathub com.keepsolid.VpnUnlimited";
    };
  };
}
