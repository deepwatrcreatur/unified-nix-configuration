# modules/home-manager/shell-aliases.nix
{ config, pkgs, lib, ... }:
let
  aliases = {
    ls = "lsd";
    ll = "lsd -l";
    la = "lsd -a";
    lla = "lsd -la";
    ".." = "cd ..";
    update = "just --justfile ~/.justfile update";
    nh-update = "just --justfile ~/.justfile nh-update";
    ssh-nocheck = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "; 
  } // lib.optionalAttrs (pkgs.stdenv.isDarwin) {
    xcode = "open -a Xcode";
  };
in
{
  programs.bash.shellAliases = aliases;
  programs.zsh.shellAliases = aliases;
  programs.fish.shellAliases = aliases;
  
  # Handle nushell separately with proper syntax
  programs.nushell.extraConfig = ''
    alias ls = ^lsd
    alias ll = ^lsd -l
    alias la = ^lsd -a
    alias lla = ^lsd -la
    alias ".." = cd ..
    alias update = ^just --justfile ~/.justfile update
    alias nh-update = ^just --justfile ~/.justfile nh-update
    ssh-nocheck = ^ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null 
    ${lib.optionalString (pkgs.stdenv.isDarwin) "alias xcode = ^open -a Xcode"}
  '';
}
