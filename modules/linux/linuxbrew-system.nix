{ config, lib, ... }:

# System-level linuxbrew directory setup
# This should be imported by Linux NixOS hosts that use homebrew

{
  # Create linuxbrew directory with proper permissions
  system.activationScripts.linuxbrew = ''
    if [ ! -d /home/linuxbrew ]; then
      mkdir -p /home/linuxbrew/.linuxbrew
      # Find the first regular user (not root) and use their ownership
      REGULAR_USER=$(getent passwd | grep -E ":[0-9]{4}:" | head -n1 | cut -d: -f1)
      if [ -n "$REGULAR_USER" ]; then
        USER_UID=$(id -u "$REGULAR_USER")
        USER_GID=$(id -g "$REGULAR_USER")
        chown -R $USER_UID:$USER_GID /home/linuxbrew
        chmod 755 /home/linuxbrew
      fi
    fi
  '';
}
