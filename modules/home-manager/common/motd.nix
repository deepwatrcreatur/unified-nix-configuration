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
    is_nixos=0
    [ -e /etc/NIXOS ] && is_nixos=1

    # Root on Proxmox/Debian hosts switches a host-specific Home Manager leaf.
    proxmox_leaf="$host-root"

    print_ip_summary() {
      if ! command -v ip >/dev/null 2>&1; then
        return 0
      fi

      # Summarize stable, globally useful addresses and skip noisy ones such as
      # IPv4 link-local, IPv6 link-local, and temporary/privacy IPv6 entries.
      summary="$(
        {
          ip -o -4 addr show up scope global 2>/dev/null | awk '
            {
              iface=$2
              split($4, parts, "/")
              addr=parts[1]
              if (addr ~ /^127\./ || addr ~ /^169\.254\./) next
              if (seen[iface SUBSEP addr]++) next
              print "10 " iface " " addr
            }
          '

          ip -o -6 addr show up scope global 2>/dev/null | awk '
            / temporary / || / mngtmpaddr / { next }
            {
              iface=$2
              split($4, parts, "/")
              addr=parts[1]
              if (addr ~ /^fe80:/) next
              if (seen[iface SUBSEP addr]++) next
              print "20 " iface " " addr
            }
          '
        } | sort -k1,1n -k2,2 -k3,3
      )"

      if [ -n "$summary" ]; then
        first_ip=1
        while IFS= read -r line; do
          [ -z "$line" ] && continue
          iface="$(printf "%s\n" "$line" | awk '{print $2}')"
          addr="$(printf "%s\n" "$line" | awk '{print $3}')"
          if [ "$first_ip" -eq 1 ]; then
            echo "IPs: $addr ($iface)"
            first_ip=0
          else
            echo "     $addr ($iface)"
          fi
        done <<EOF
$summary
EOF
      fi
    }

    echo
    hr
    echo "Host: $host"
    [ -n "$now" ] && echo "Time: $now"
    echo "Repo: $repo"
    echo

    echo "Common commands:"
    echo "  - NixOS:   nh os switch -H $host -f $repo"
    if [ "$is_nixos" -eq 0 ] && [ "$(id -u)" -eq 0 ]; then
      echo "  - Proxmox: cd $repo && home-manager switch --flake .#$proxmox_leaf"
    else
      echo "  - Proxmox: cd $repo && home-manager switch --flake .#''${host}-root"
    fi
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
      nixver="$(timeout 3s nix --version 2>/dev/null || true)"
      [ -n "$nixver" ] && echo "Nix: $nixver"
    fi

    if command -v determinate-nixd >/dev/null 2>&1; then
      # determinate-nixd status talks to a daemon socket; guard with a timeout
      # so a slow/absent daemon does not stall the SSH login.
      det="$(timeout 3s determinate-nixd status 2>/dev/null | head -n 3 | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' || true)"
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

    print_ip_summary

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
    enable = lib.mkEnableOption "login motd banner" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {

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
