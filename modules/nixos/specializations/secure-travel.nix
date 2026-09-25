# modules/nixos/specializations/secure-travel.nix
# Hardened travel / mobile specialization module.
# Provides network privacy, MAC randomization, VPN drop notification,
# DNS-over-TLS, sysctl kernel hardening, and attack surface reduction.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.myModules.specializations.secureTravel;
in
{
  options.myModules.specializations.secureTravel = {
    enable = mkEnableOption "secure travel hardened specialization";
  };

  config = mkIf cfg.enable {
    specialisation.secure-travel.configuration =
      { options, ... }:
      {
        system.nixos.tags = [ "secure-travel" ];

        # ---------------------------------------------------------
        # 1. 🛡️ KERNEL & SYSTEM HARDENING
        # ---------------------------------------------------------
        boot.kernel.sysctl = {
          # Kernel hardening
          "kernel.kptr_restrict" = 2; # Hide kernel pointers from unprivileged users
          "kernel.dmesg_restrict" = 1; # Restrict dmesg to root only
          "kernel.sysrq" = 4; # Only allow SAK (Secure Attention Key)
          "kernel.perf_event_paranoid" = 3; # Disable perf events for unprivileged users
          "kernel.unprivileged_bpf_disabled" = 1; # Disable BPF for unprivileged users
          "net.core.bpf_jit_harden" = 2; # Harden BPF JIT compiler
          "kernel.yama.ptrace_scope" = 2; # Restrict ptrace to root only

          # Network hardening - ICMP redirects (prevent MITM route hijacking)
          "net.ipv4.conf.all.accept_redirects" = 0;
          "net.ipv4.conf.default.accept_redirects" = 0;
          "net.ipv6.conf.all.accept_redirects" = 0;
          "net.ipv6.conf.default.accept_redirects" = 0;
          "net.ipv4.conf.all.send_redirects" = 0;
          "net.ipv4.conf.default.send_redirects" = 0;

          # Network hardening - Source routing (prevent IP spoofing)
          "net.ipv4.conf.all.accept_source_route" = 0;
          "net.ipv4.conf.default.accept_source_route" = 0;
          "net.ipv6.conf.all.accept_source_route" = 0;
          "net.ipv6.conf.default.accept_source_route" = 0;

          # Network hardening - Reverse path filtering (anti-spoofing)
          "net.ipv4.conf.all.rp_filter" = 1;
          "net.ipv4.conf.default.rp_filter" = 1;

          # Network hardening - Misc protections
          "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
          "net.ipv4.tcp_syncookies" = 1;
          "net.ipv4.conf.all.log_martians" = 1;
          "net.ipv4.conf.default.log_martians" = 1;
        };

        # Lock root account in travel mode
        users.users.root = {
          hashedPassword = lib.mkForce "!";
          hashedPasswordFile = lib.mkForce null;
        };

        # ---------------------------------------------------------
        # 2. 📴 ATTACK SURFACE REDUCTION
        # ---------------------------------------------------------
        # Disable Bluetooth on travel mode
        hardware.bluetooth.enable = lib.mkForce false;

        # Disable binary compatibility shims
        programs = {
          nix-ld.enable = lib.mkForce false;
        } // lib.optionalAttrs (options ? programs && options.programs ? nix-alien) {
          nix-alien.enable = lib.mkForce false;
        };

        # Disallow local broadcast discovery and VPN side-channels
        services.avahi = {
          enable = lib.mkForce false;
          nssmdns4 = lib.mkForce false;
        };
        services.tailscale.enable = lib.mkForce false;

        # ---------------------------------------------------------
        # 3. 🔒 VPN PACKAGES & AUTOSTART
        # ---------------------------------------------------------
        environment.systemPackages = with pkgs; [
          proton-vpn
        ] ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
          tor-browser
        ];

        # Autostart ProtonVPN across desktop sessions
        environment.etc."xdg/autostart/protonvpn.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=ProtonVPN
          Exec=sh -c 'sleep 3 && protonvpn-app --start-minimized'
          Hidden=false
          NoDisplay=false
          X-GNOME-Autostart-enabled=true
        '';

        # ---------------------------------------------------------
        # 4. 🌐 NETWORK: MAC RANDOMIZATION, KILLSWITCH, FIREWALL & SECURE DNS
        # ---------------------------------------------------------
        networking = {
          nameservers = [
            "9.9.9.9"
            "149.112.112.112"
            "2620:fe::fe"
            "2620:fe::9"
          ];

          networkmanager = {
            wifi.macAddress = "random";
            ethernet.macAddress = "random";

            dispatcherScripts = [
              {
                source = pkgs.writeShellScript "vpn-killswitch" ''
                  #!/bin/sh
                  INTERFACE=$1
                  STATUS=$2

                  if [ "$INTERFACE" = "proton0" ] || [ "$INTERFACE" = "tun0" ]; then
                    if [ "$STATUS" = "down" ]; then
                      for u in $(users 2>/dev/null | tr ' ' '\n' | sort -u); do
                        uid=$(id -u "$u" 2>/dev/null || true)
                        if [ -n "$uid" ] && [ -e "/run/user/$uid/bus" ]; then
                          sudo -u "$u" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
                            ${pkgs.libnotify}/bin/notify-send -u critical "VPN Disconnected" "VPN connection lost. Traffic is NOT protected." 2>/dev/null || true
                        fi
                      done
                      ${pkgs.libnotify}/bin/notify-send -u critical "VPN Disconnected" "VPN connection lost. Traffic is NOT protected." 2>/dev/null || true
                    elif [ "$STATUS" = "up" ]; then
                      for u in $(users 2>/dev/null | tr ' ' '\n' | sort -u); do
                        uid=$(id -u "$u" 2>/dev/null || true)
                        if [ -n "$uid" ] && [ -e "/run/user/$uid/bus" ]; then
                          sudo -u "$u" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
                            ${pkgs.libnotify}/bin/notify-send -u normal "VPN Connected" "VPN is active. Traffic is protected." 2>/dev/null || true
                        fi
                      done
                      ${pkgs.libnotify}/bin/notify-send -u normal "VPN Connected" "VPN is active. Traffic is protected." 2>/dev/null || true
                    fi
                  fi
                '';
                type = "basic";
              }
            ];
          };

          firewall = {
            enable = true;
            allowedTCPPorts = lib.mkForce [ ];
            allowedUDPPorts = lib.mkForce [ ];
            logRefusedConnections = true;
            logRefusedPackets = true;
          };
        };

        services.resolved = {
          enable = true;
          settings.Resolve = {
            DNSSEC = lib.mkForce "allow-downgrade"; # DNSSEC with captive portal fallback
            Domains = lib.mkForce "~."; # Route all DNS through resolved
            FallbackDNS = lib.mkForce "1.1.1.1 8.8.8.8"; # Fallback for captive portals
            DNSOverTLS = lib.mkForce "opportunistic"; # DoT when available, plain for portals
          };
        };
      };
  };
}
