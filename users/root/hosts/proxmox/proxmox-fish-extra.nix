# users/root/hosts/proxmox-fish-extra.nix
{ config, pkgs, lib, ... }:
{
  programs.fish.shellInit = lib.mkAfter ''
    # Nix integration for Fish shell (Proxmox only)
    if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    end
  '';
}

