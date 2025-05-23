#!/bin/sh
LOG="/tmp/nix-darwin-activation.log"
echo "$(date): Running fix-nix-mount-plist.sh" >> "$LOG"
PLIST="/Library/LaunchDaemons/com.nix.mount.plist"
# Wait up to 5 seconds for plist to appear
for i in {1..5}; do
  if [ -f "$PLIST" ]; then
    echo "$(date): Found $PLIST, setting permissions" >> "$LOG"
    /bin/chmod 644 "$PLIST" 2>> "$LOG" || {
      echo "$(date): Failed to chmod 644 $PLIST" >> "$LOG"
      exit 1
    }
    /bin/chown root:wheel "$PLIST" 2>> "$LOG" || {
      echo "$(date): Failed to chown $PLIST" >> "$LOG"
      exit 1
    }
    echo "$(date): Successfully set permissions on $PLIST" >> "$LOG"
    exit 0
  fi
  echo "$(date): Waiting for $PLIST ($i/5)" >> "$LOG"
  sleep 1
done
echo "$(date): Error: $PLIST not found after 5 seconds" >> "$LOG"
exit 1
