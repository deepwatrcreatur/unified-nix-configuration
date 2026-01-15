{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.motd;

  motdScript = pkgs.writeShellScriptBin "motd" ''
    set -u

    hr() {
      width="''${MOTD_WIDTH:-72}"
      printf '%*s\n' "$width" "" | tr ' ' '-'
    }

    host="$(hostname 2>/dev/null || echo unknown)"
    now="$(date -Is 2>/dev/null || true)"

    # Default to the standard location our shortcuts expect.
    repo="''${MOTD_FLAKE_REPO:-$HOME/flakes/unified-nix-configuration}"

    echo
    hr
    echo "Host: $host"
    [ -n "$now" ] && echo "Time: $now"
    echo "Repo: $repo"
    echo

    echo "Common commands:"
    echo "  - NixOS:   nh os switch -H $host -f $repo"
    echo "  - Proxmox: cd $repo && home-manager switch --flake .#proxmox-root"
    echo

    if command -v git >/dev/null 2>&1 && [ -d "$repo/.git" ]; then
      rev="$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || true)"
      branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
      if [ -n "$rev" ]; then
        echo "Config: $branch@$rev"
        echo
      fi
    fi

    if command -v nix >/dev/null 2>&1; then
      nixver="$(nix --version 2>/dev/null || true)"
      [ -n "$nixver" ] && echo "Nix: $nixver"
    fi

    if command -v determinate-nixd >/dev/null 2>&1; then
      det="$(determinate-nixd status 2>/dev/null | head -n 3 | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' || true)"
      [ -n "$det" ] && echo "Determinate: $det"
    fi

    if command -v uptime >/dev/null 2>&1; then
      up="$(uptime 2>/dev/null || true)"
      [ -n "$up" ] && echo "Uptime: $up"
    fi

    if command -v df >/dev/null 2>&1; then
      rootdf="$(df -h / 2>/dev/null | awk 'NR==2 {print $4" free of "$2" ("$5" used)"}' || true)"
      [ -n "$rootdf" ] && echo "Disk(/): $rootdf"
    fi

    if command -v free >/dev/null 2>&1; then
      mem="$(free -h 2>/dev/null | awk '/Mem:/ {print $7" free of "$2""}' || true)"
      [ -n "$mem" ] && echo "Mem: $mem"
    fi

    if command -v hostname >/dev/null 2>&1; then
      ips="$(hostname -I 2>/dev/null | tr -s ' ' | sed 's/[[:space:]]*$//' || true)"
      [ -n "$ips" ] && echo "IPs: $ips"
    fi

    hr
  '';

  bashHook = ''
    # MOTD (once per SSH session)
    if [ -z "''${__MOTD_SHOWN-}" ] && [ -n "''${SSH_CONNECTION-}" ]; then
      export __MOTD_SHOWN=1
      if command -v motd >/dev/null 2>&1; then motd || true; fi
    fi
  '';

  zshHook = ''
    # MOTD (once per SSH session)
    if [[ -z "''${__MOTD_SHOWN-}" && -n "''${SSH_CONNECTION-}" ]]; then
      export __MOTD_SHOWN=1
      if command -v motd >/dev/null 2>&1; then motd || true; fi
    fi
  '';

  fishHook = ''
    # MOTD (once per SSH session)
    if status is-interactive
      if set -q SSH_CONNECTION
        if not set -q __MOTD_SHOWN
          set -gx __MOTD_SHOWN 1
          if type -q motd
            motd
          end
        end
      end
    end
  '';

in
{
  options.custom.motd = {
    enable = lib.mkEnableOption "login motd banner";
  };

  config = lib.mkIf cfg.enable {
    custom.motd.enable = lib.mkDefault true;

    home.packages = [ motdScript ];

    # Dynamic banner on SSH logins
    programs.bash.initExtra = lib.mkAfter bashHook;
    programs.zsh.initContent = lib.mkAfter zshHook;
    programs.fish.interactiveShellInit = lib.mkAfter fishHook;

    # Static /etc/motd for non-NixOS (e.g. Proxmox) when using root HM
    home.activation.writeEtcMotd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ "$(id -u)" -eq 0 ] && [ ! -e /etc/NIXOS ]; then
        install -m 644 /dev/null /etc/motd
        {
          echo "Host: $(hostname 2>/dev/null || echo unknown)"
          echo "Repo: $HOME/flakes/unified-nix-configuration"
          echo "Hint: use 'motd' for live status"
        } > /etc/motd
      fi
    '';
  };
}
