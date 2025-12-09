# karabiner.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib.strings) toJSON;
  allBasic = map (x: x // { type = "basic"; });

  # Core caps lock ↔ escape swap
  simple_modifications = [
    {
      from.key_code = "caps_lock";
      to = [ { key_code = "escape"; } ];
    }
    {
      from.key_code = "escape";
      to = [ { key_code = "caps_lock"; } ];
    }
  ];

  # Optional useful modifications (comment out what you don't want)
  complex_modifications.rules = [
    # Hyper key: caps lock + modifier keys become a "hyper" modifier
    # Useful for app-specific shortcuts without conflicts
    {
      description = "Caps Lock + hjkl → Arrow Keys (Vim-style navigation)";
      manipulators = allBasic [
        {
          from.key_code = "h";
          from.modifiers.mandatory = [ "caps_lock" ];
          to = [ { key_code = "left_arrow"; } ];
        }
        {
          from.key_code = "j";
          from.modifiers.mandatory = [ "caps_lock" ];
          to = [ { key_code = "down_arrow"; } ];
        }
        {
          from.key_code = "k";
          from.modifiers.mandatory = [ "caps_lock" ];
          to = [ { key_code = "up_arrow"; } ];
        }
        {
          from.key_code = "l";
          from.modifiers.mandatory = [ "caps_lock" ];
          to = [ { key_code = "right_arrow"; } ];
        }
      ];
    }
  ];

  karabinerConfig = {
    global.show_in_menu_bar = false;

    profiles = [
      {
        inherit complex_modifications simple_modifications;

        name = "Default";
        selected = true;

        virtual_hid_keyboard.keyboard_type_v2 = "ansi";

        devices = [
          {
            identifiers.is_keyboard = true;
          }
        ];
      }
    ];
  };
in
{
  # Configure karabiner config file
  xdg.configFile."karabiner/karabiner.json" = {
    text = toJSON karabinerConfig;
  };
}
