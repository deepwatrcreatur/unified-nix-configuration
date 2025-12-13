# modules/activation-scripts/darwin/fix-homebrew-taps.nix
# Fix broken Homebrew Taps symlink for nix-homebrew with mutableTaps

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.activation-scripts.darwin.fix-homebrew-taps;
  
  fixHomebrewTapsScript = pkgs.writeShellScript "fix-homebrew-taps" ''
    TAPS_PATH="/opt/homebrew/Library/Taps"
    
    # Check if Taps is a broken symlink
    if [ -L "$TAPS_PATH" ]; then
      TARGET=$(readlink "$TAPS_PATH" 2>/dev/null || true)
      if [ ! -e "$TARGET" ]; then
        echo "Removing broken Taps symlink pointing to: $TARGET"
        rm "$TAPS_PATH"
        echo "Creating mutable Taps directory"
        mkdir -p "$TAPS_PATH"
        chown ${config.system.primaryUser}:admin "$TAPS_PATH"
        chmod 755 "$TAPS_PATH"
      fi
    elif [ ! -d "$TAPS_PATH" ]; then
      echo "Creating missing Taps directory"
      mkdir -p "$TAPS_PATH"
      chown ${config.system.primaryUser}:admin "$TAPS_PATH"
      chmod 755 "$TAPS_PATH"
    fi
  '';
in
{
  options.custom.activation-scripts.darwin.fix-homebrew-taps = {
    enable = lib.mkEnableOption "Fix broken Homebrew Taps symlink" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.preActivation.text = ''
      echo "Checking Homebrew Taps directory..."
      ${fixHomebrewTapsScript}
    '';
  };
}
