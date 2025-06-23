{ config, lib, pkgs, inputs, ... }:

{
  # Import SOPS Home Manager module
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  home.packages = [
    pkgs.rclone
    pkgs.sops # Ensure sops is available for decryption
  ];

  # Write rclone filter file to ~/.config/rclone/rclone-filter.txt
  home.file.".config/rclone/rclone-filter.txt".text = ''
    # Exclude common macOS system files
    - .DS_Store
    - .AppleDouble
    - .LSOverride
    - .DocumentRevisions-V100
    - .fseventsd
    - .Spotlight-V100
    - .Trashes

    # Exclude common Windows system files
    - Thumbs.db
    - desktop.ini
    - $RECYCLE.BIN/
    - System Volume Information/

    # Exclude temporary and cache files
    - *.tmp
    - *.temp
    - *.bak
    - *.swp
    - *.~*
    - *~

    # Exclude common application cache and log files
    - *.log
    - *.cache
    - node_modules/
    - __pycache__/
    - *.pyc
    - *.pyo

    # Exclude common version control files
    - .git/
    - .gitignore
    - .gitattributes
    - .hg/
    - .svn/

    # Include everything else (catch-all)
    + **
  '';
 
  xdg.configFile."rclone/rclone.conf" = {
    source = lib.sops.readText ../../secrets/rclone.conf;

    # Set permissions if needed (rclone usually needs 0o600 for security)
    mode = "0600";
  };
}
