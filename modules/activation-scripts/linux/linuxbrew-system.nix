{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.activation-scripts.linux.linuxbrew-system;
  compatLinks = [
    [ "${pkgs.coreutils}/bin/nice" "/usr/bin/nice" ]
    [ "${pkgs.coreutils}/bin/mkdir" "/bin/mkdir" ]
    [ "${pkgs.coreutils}/bin/chmod" "/bin/chmod" ]
    [ "${pkgs.coreutils}/bin/chown" "/bin/chown" ]
    [ "${pkgs.coreutils}/bin/chgrp" "/bin/chgrp" ]
    [ "${pkgs.coreutils}/bin/touch" "/bin/touch" ]
    [ "${pkgs.coreutils}/bin/readlink" "/bin/readlink" ]
    [ "${pkgs.coreutils}/bin/cat" "/bin/cat" ]
    [ "${pkgs.coreutils}/bin/sort" "/bin/sort" ]
    [ "${pkgs.coreutils}/bin/mv" "/bin/mv" ]
    [ "${pkgs.coreutils}/bin/rm" "/bin/rm" ]
    [ "${pkgs.coreutils}/bin/ln" "/bin/ln" ]
    [ "${pkgs.coreutils}/bin/dirname" "/bin/dirname" ]
    [ "${pkgs.coreutils}/bin/basename" "/bin/basename" ]
    [ "${pkgs.coreutils}/bin/uname" "/bin/uname" ]
    [ "${pkgs.coreutils}/bin/sha256sum" "/bin/sha256sum" ]
    [ "${pkgs.gnutar}/bin/tar" "/bin/tar" ]
    [ "${pkgs.gzip}/bin/gzip" "/bin/gzip" ]
    [ "${pkgs.gnugrep}/bin/grep" "/bin/grep" ]
    [ "${pkgs.bash}/bin/bash" "/bin/bash" ]
    [ "${pkgs.util-linux}/bin/flock" "/usr/bin/flock" ]
    [ "${pkgs.coreutils}/bin/stat" "/usr/bin/stat" ]
    [ "${pkgs.coreutils}/bin/cut" "/usr/bin/cut" ]
    [ "${pkgs.coreutils}/bin/dirname" "/usr/bin/dirname" ]
    [ "${pkgs.coreutils}/bin/sha256sum" "/usr/bin/sha256sum" ]
    [ "${pkgs.glibc.bin}/bin/ldd" "/usr/bin/ldd" ]
  ];

  linuxbrewSystemScript = pkgs.writeShellScript "linuxbrew-system.sh" ''
    # Create linuxbrew directory with proper permissions
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

    # Homebrew's installer expects a handful of absolute /bin and /usr/bin paths.
    mkdir -p /bin /usr/bin
    ${lib.concatMapStringsSep "\n" (link: ''ln -sf ${builtins.elemAt link 0} ${builtins.elemAt link 1}'') compatLinks}
  '';
in
{
  options.custom.activation-scripts.linux.linuxbrew-system = {
    enable = lib.mkEnableOption "Linuxbrew system directory setup script";
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.linuxbrew.text = lib.mkAfter ''
      echo "Running Linuxbrew system setup script and compatibility link setup..."
      ${linuxbrewSystemScript}
    '';
  };
}
