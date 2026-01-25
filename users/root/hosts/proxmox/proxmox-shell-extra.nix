# users/root/hosts/proxmox/proxmox-shell-extra.nix
{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.bash.initExtra = lib.mkAfter ''
    # Nix integration for Bash shell (Proxmox only)
    if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    # Add home-manager-path to PATH for tools like atuin, fnox, etc.
    if [ -d /root/.nix-profile/bin ]; then
      export PATH="$HOME/.nix-profile/bin:$PATH"
    fi
  '';

  programs.fish.shellInit = lib.mkAfter ''
    # Nix integration for Fish shell (Proxmox only)
    if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    end
  '';
}
