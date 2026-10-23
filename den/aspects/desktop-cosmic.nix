# den/aspects/desktop-cosmic.nix
# COSMIC Desktop Environment aspect with greetd, package exclusions, and Vicinae launcher
{
  primaryUser ? "deepwatrcreatur",
  ...
}:
{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../modules/nixos/sessions/cosmic.nix
  ];

  home-manager.users.${primaryUser} = {
    programs.vicinae.enable = true;

    xdg.configFile."cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom".text = ''
      {
          (
              modifiers: [Alt],
              key: "space",
              description: Some("Vicinae Launcher"),
          ): Spawn("${pkgs.vicinae}/bin/vicinae toggle"),
      }
    '';
  };
}
