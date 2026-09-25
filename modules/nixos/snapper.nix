{
  config,
  lib,
  pkgs,
  ...
}:

let
  snapCreate = pkgs.writeShellScriptBin "_snap-create" ''
    config_name="$1"
    if [ -z "$config_name" ]; then
      echo "❌ Usage: _snap-create <config>"
      exit 1
    fi

    read -p "📝 Enter snapshot description: " description
    if [ -z "$description" ]; then
      echo "❌ Description cannot be empty."
      exit 1
    fi

    read -p "🔒 Lock this snapshot (keep forever)? [y/N]: " lock_ans
    cleanup_flag="-c timeline"
    lock_status="UNLOCKED (will auto-delete)"
    if [[ "$lock_ans" =~ ^[Yy]$ ]]; then
      cleanup_flag=""
      lock_status="LOCKED (safe forever)"
    fi

    echo "🚀 Creating $lock_status snapshot for '$config_name'..."
    sudo snapper -c "$config_name" create --description "$description" $cleanup_flag
  '';

  snapLock = pkgs.writeShellScriptBin "snap-lock" ''
    echo "Which config? (1=home, 2=root)"
    read -p "Selection: " k
    if [ "$k" = "2" ]; then CFG="root"; else CFG="home"; fi
    sudo snapper -c "$CFG" list
    echo ""
    read -p "Enter Snapshot ID to LOCK: " ID
    if [ -n "$ID" ]; then
      sudo snapper -c "$CFG" modify -c "" "$ID"
      echo "✅ Snapshot #$ID in '$CFG' is now LOCKED."
    fi
  '';

  snapUnlock = pkgs.writeShellScriptBin "snap-unlock" ''
    echo "Which config? (1=home, 2=root)"
    read -p "Selection: " k
    if [ "$k" = "2" ]; then CFG="root"; else CFG="home"; fi
    sudo snapper -c "$CFG" list
    echo ""
    read -p "Enter Snapshot ID to UNLOCK: " ID
    if [ -n "$ID" ]; then
      sudo snapper -c "$CFG" modify -c "timeline" "$ID"
      echo "✅ Snapshot #$ID in '$CFG' is now UNLOCKED."
    fi
  '';

  snapCreateHome = pkgs.writeShellScriptBin "snap-create-home" ''
    exec ${snapCreate}/bin/_snap-create home
  '';

  snapCreateRoot = pkgs.writeShellScriptBin "snap-create-root" ''
    exec ${snapCreate}/bin/_snap-create root
  '';
in
{
  services.snapper = {
    snapshotInterval = "hourly";

    configs = {
      root = {
        SUBVOLUME = "/";
        FSTYPE = "btrfs";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 6;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 2;
        TIMELINE_LIMIT_YEARLY = 0;
      };

      home = {
        SUBVOLUME = "/home";
        FSTYPE = "btrfs";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 3;
        TIMELINE_LIMIT_DAILY = 5;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 1;
        TIMELINE_LIMIT_YEARLY = 0;
      };
    };
  };

  environment.systemPackages = lib.mkIf (config.services.snapper.configs != {}) (
    with pkgs;
    [
      snapper
      btrfs-progs
      btrfs-assistant
      snapCreate
      snapCreateHome
      snapCreateRoot
      snapLock
      snapUnlock
    ]
  );

  # Allow the primary user to work with snapshots.
  users.users.deepwatrcreatur.extraGroups = lib.mkAfter [ "snapper" ];
}
