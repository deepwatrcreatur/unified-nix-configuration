# Update determinate nix mount script with current UUID
if [ -f /usr/local/bin/mount-nix-ssd.sh ]; then
  echo "Updating determinate nix mount script with UUID: ${cfg.uuid}"
  /usr/bin/sed -i "" "s/SSD_UUID=\".*\"/SSD_UUID=\"${cfg.uuid}\"/" /usr/local/bin/mount-nix-ssd.sh || true
fi