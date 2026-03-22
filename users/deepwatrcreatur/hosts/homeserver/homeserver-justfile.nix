# users/deepwatrcreatur/hosts/homeserver/homeserver-justfile.nix
{
  my.just = {
    flakeTarget = "homeserver";
    extraRecipes = ''
      # Pull latest and rebuild
      pull-update:
          cd $NH_FLAKE && git pull --ff-only origin main && just update
    '';
  };
}
