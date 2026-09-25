# den/aspects/user-server.nix
# Composes server user persona aspect into primaryUser.
{
  primaryUser ? "deepwatrcreatur",
  ...
}:
{ ... }:
{
  home-manager.users.${primaryUser}.imports = [
    ../../users/${primaryUser}/aspects/server.nix
  ];
}
