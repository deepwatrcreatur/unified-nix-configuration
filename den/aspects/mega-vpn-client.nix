# den/aspects/mega-vpn-client.nix
# MEGA VPN & Desktop client aspect for workstations.
# MEGA VPN on Linux operates via WireGuard (.conf) configuration profiles.
# This aspect equips the host with WireGuard tools, NetworkManager integration,
# a dedicated `mega-vpn` management CLI, and the official MEGAsync desktop app.

{ ... }:
{
  pkgs,
  lib,
  ...
}:
let
  megaVpnHelper = pkgs.writeShellScriptBin "mega-vpn" ''
    set -euo pipefail

    CONFIG_DIR="/etc/wireguard"

    show_help() {
      cat <<'EOF'
MEGA VPN - WireGuard Connection Helper

Usage:
  mega-vpn up [name]           Connect to a MEGA VPN profile (default: first found)
  mega-vpn down [name]         Disconnect from MEGA VPN
  mega-vpn status              Show active WireGuard tunnel and current public IP
  mega-vpn list                List available MEGA VPN profiles
  mega-vpn import <file.conf> [name]  Import a downloaded .conf into /etc/wireguard
  mega-vpn import-nm <file.conf>      Import a .conf into NetworkManager (for GUI toggle)
  mega-vpn help                Show this help message

How to get MEGA VPN credentials:
  1. Log into your account at https://mega.nz/fm/account/vpn
  2. Select your desired region/server and click "Generate VPN credentials"
  3. Download the .conf file and run:
     mega-vpn import ~/Downloads/<file>.conf [optional-name]
     mega-vpn up [optional-name]
EOF
    }

    cmd="''${1:-help}"

    case "$cmd" in
      up)
        profile="''${2:-}"
        if [ -z "$profile" ]; then
          profile=$(sudo find "$CONFIG_DIR" -maxdepth 1 -name "mega*.conf" -o -name "*.conf" 2>/dev/null | head -n 1 | xargs -r basename -s .conf || true)
        fi
        if [ -z "$profile" ]; then
          echo "Error: No WireGuard profile found in $CONFIG_DIR."
          echo "Import one using: mega-vpn import /path/to/profile.conf [name]"
          exit 1
        fi
        echo "Bringing up MEGA VPN tunnel: $profile..."
        sudo ${pkgs.wireguard-tools}/bin/wg-quick up "$profile"
        echo ""
        echo "Checking connection..."
        sleep 1
        sudo ${pkgs.wireguard-tools}/bin/wg show
        ;;

      down)
        profile="''${2:-}"
        if [ -z "$profile" ]; then
          active=$(sudo ${pkgs.wireguard-tools}/bin/wg show interfaces 2>/dev/null || true)
          if [ -z "$active" ]; then
            echo "No active WireGuard interfaces found."
            exit 0
          fi
          profile=$(echo "$active" | awk '{print $1}')
        fi
        echo "Tearing down MEGA VPN tunnel: $profile..."
        sudo ${pkgs.wireguard-tools}/bin/wg-quick down "$profile"
        ;;

      status)
        echo "=== WireGuard Interface Status ==="
        sudo ${pkgs.wireguard-tools}/bin/wg show || echo "No active WireGuard tunnel."
        echo ""
        echo "=== Public IP & Egress ==="
        ip_info=$(${pkgs.curl}/bin/curl -s --max-time 5 https://ipinfo.io/json 2>/dev/null || true)
        if [ -n "$ip_info" ]; then
          echo "$ip_info" | ${pkgs.jq}/bin/jq -r '"IP: \(.ip // "Unknown")\nLocation: \(.city // "Unknown"), \(.region // ""), \(.country // "")\nOrg: \(.org // "Unknown")"' 2>/dev/null || echo "$ip_info"
        else
          current_ip=$(${pkgs.curl}/bin/curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "Unavailable")
          echo "Current Public IP: $current_ip"
        fi
        ;;

      list)
        echo "Available profiles in $CONFIG_DIR:"
        sudo ls -1 "$CONFIG_DIR"/*.conf 2>/dev/null | while read -r f; do
          name=$(basename -s .conf "$f")
          echo "  - $name ($f)"
        done || echo "  (None found)"
        ;;

      import)
        src="''${2:-}"
        if [ -z "$src" ] || [ ! -f "$src" ]; then
          echo "Error: Please specify a valid .conf file to import."
          echo "Usage: mega-vpn import <file.conf> [name]"
          exit 1
        fi
        target_name="''${3:-}"
        if [ -z "$target_name" ]; then
          target_name="mega-$(basename -s .conf "$src" | tr '[:upper:]' '[:lower:]')"
        fi
        target_path="$CONFIG_DIR/$target_name.conf"
        sudo mkdir -p "$CONFIG_DIR"
        sudo cp "$src" "$target_path"
        sudo chmod 600 "$target_path"
        echo "Imported profile to $target_path"
        echo "To connect, run: mega-vpn up $target_name"
        ;;

      import-nm)
        src="''${2:-}"
        if [ -z "$src" ] || [ ! -f "$src" ]; then
          echo "Error: Please specify a valid .conf file to import into NetworkManager."
          echo "Usage: mega-vpn import-nm <file.conf>"
          exit 1
        fi
        echo "Importing $src into NetworkManager..."
        ${pkgs.networkmanager}/bin/nmcli connection import type wireguard file "$src"
        echo "Profile imported into NetworkManager. You can now toggle it from your panel applet or run: nmcli connection up <name>"
        ;;

      help|--help|-h)
        show_help
        ;;

      *)
        echo "Unknown command: $cmd"
        show_help
        exit 1
        ;;
    esac
  '';
in
{
  environment.systemPackages = [
    pkgs.wireguard-tools
    pkgs.openresolv
    pkgs.megasync
    pkgs.megacmd
    megaVpnHelper
  ];

  networking.wireguard.enable = true;
}
