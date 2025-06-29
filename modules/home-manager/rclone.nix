# modules/home-manager/rclone.nix

{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  home.packages = [
    pkgs.rclone
    pkgs.sops
  ];

  xdg.configFile."rclone/rclone-filter.txt".text = ''
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

  #home.file.".config/rclone/rclone.conf" = {
  #  source = sopsLib.readText ../../secrets/rclone.conf;
  #  executable = false;
  #};
}
