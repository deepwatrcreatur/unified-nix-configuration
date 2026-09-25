# den/aspects/user-desktop-whitesur.nix
# Composes desktop-whitesur GUI persona aspect into primaryUser.
{
  primaryUser ? "deepwatrcreatur",
  ...
}:
{ ... }:
{
  home-manager.users.${primaryUser}.imports = [
    ../../users/${primaryUser}/aspects/desktop-whitesur.nix
  ];
}
