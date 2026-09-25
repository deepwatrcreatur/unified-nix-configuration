# den/aspects/user-developer.nix
# Composes developer user persona aspect into primaryUser.
{
  primaryUser ? "deepwatrcreatur",
  ...
}:
{ ... }:
{
  home-manager.users.${primaryUser}.imports = [
    ../../users/${primaryUser}/aspects/developer.nix
  ];
}
