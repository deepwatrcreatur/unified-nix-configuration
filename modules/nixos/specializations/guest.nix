# modules/nixos/specializations/guest.nix
# Ephemeral guest specialization module.
# Provides a disposable guest account with a tmpfs-backed home directory,
# mesh network isolation (Tailscale rejection), resource limits, hardened browser policies,
# and an informative welcome dialog.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myModules.specializations.guest;

  guestWelcomeScript = pkgs.writeShellScriptBin "guest-welcome" ''
    # Wait for the session desktop and notifications to settle
    sleep 3
    ${pkgs.zenity}/bin/zenity --warning \
      --title="Guest Session" \
      --width=440 \
      --text="<span size='large' weight='bold'>Temporary Guest Session</span>\n\nAll personal data, downloaded files, and browser history are stored in memory and will be completely wiped on logout or reboot.\n\nPlease save any files you wish to keep to an external USB drive or cloud service."
  '';
in
{
  options.myModules.specializations.guest = {
    enable = lib.mkEnableOption "ephemeral guest account specialization";
  };

  config = lib.mkIf cfg.enable {
    specialisation.guest.configuration =
      { options, ... }:
      {
        system.nixos.tags = [ "guest" ];

        # ---------------------------------------------------------
        # 1. 👤 GUEST USER ACCOUNT & TMPFS HOME
        # ---------------------------------------------------------
        users.users.guest = {
          isNormalUser = true;
          description = "Guest Account";
          uid = 2000;
          group = "guest";
          extraGroups = [
            "networkmanager"
            "audio"
            "video"
          ];
          createHome = true;
        };
        users.groups.guest.gid = 2000;

        fileSystems."/home/guest" = {
          device = "none";
          fsType = "tmpfs";
          options = [
            "size=25%"
            "mode=700"
            "uid=2000"
            "gid=2000"
            "nosuid"
            "nodev"
            "noatime"
          ];
        };

        # ---------------------------------------------------------
        # 2. 🛡️ MESH NETWORK ISOLATION & TAILSCALE PROTECTION
        # ---------------------------------------------------------
        networking.firewall.extraCommands = ''
          # Block guest account from reaching Tailscale interface or CGNAT range
          iptables -A OUTPUT -m owner --uid-owner 2000 -o tailscale0 -j REJECT 2>/dev/null || true
          iptables -A OUTPUT -m owner --uid-owner 2000 -d 100.64.0.0/10 -j REJECT 2>/dev/null || true
        '';

        # ---------------------------------------------------------
        # 3. ⚙️ RESOURCE LIMITS & CPU WEIGHT
        # ---------------------------------------------------------
        systemd.slices."user-2000".sliceConfig = {
          MemoryMax = "75%";
          CPUWeight = 90;
        };

        # ---------------------------------------------------------
        # 4. 🌐 HARDENED BROWSER POLICIES & UTILITIES
        # ---------------------------------------------------------
        programs.firefox = {
          enable = true;
          policies = {
            DisableFirstRunPage = true;
            DontCheckDefaultBrowser = true;
            DisableTelemetry = true;
            DisablePocket = true;
          };
        };

        environment.systemPackages = with pkgs; [
          zenity
          guestWelcomeScript
        ];

        # Autostart guest welcome banner across sessions
        environment.etc."xdg/autostart/guest-welcome.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Guest Welcome
          Exec=${guestWelcomeScript}/bin/guest-welcome
          Hidden=false
          NoDisplay=false
          X-GNOME-Autostart-enabled=true
        '';

        # ---------------------------------------------------------
        # 5. 🔑 DISPLAY MANAGER AUTO-LOGIN OVERRIDE
        # ---------------------------------------------------------
        services.displayManager.autoLogin = {
          enable = lib.mkForce true;
          user = lib.mkForce "guest";
        };

        services.greetd.settings.initial_session = {
          user = lib.mkForce "guest";
        };
      };
  };
}
