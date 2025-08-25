# karabiner.nix
{ lib, ... }: 

let
  inherit (lib.strings) toJSON;
  allBasic = map (x: x // { type = "basic"; });

  # Core caps lock ↔ escape swap
  simple_modifications = [
    {
      from.key_code = "caps_lock";
      to = [{ key_code = "escape"; }];
    }
    {
      from.key_code = "escape";
      to = [{ key_code = "caps_lock"; }];
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
          to = [{ key_code = "left_arrow"; }];
        }
        {
          from.key_code = "j";
          from.modifiers.mandatory = [ "caps_lock" ];
          to = [{ key_code = "down_arrow"; }];
        }
        {
          from.key_code = "k";
          from.modifiers.mandatory = [ "caps_lock" ];
          to = [{ key_code = "up_arrow"; }];
        }
        {
          from.key_code = "l";
          from.modifiers.mandatory = [ "caps_lock" ];
          to = [{ key_code = "right_arrow"; }];
        }
      ];
    }

    # Right Command → Right Option (for better window management)
    # Many people find right cmd less useful than right option
    # {
    #   description = "Right Command → Right Option";
    #   manipulators = allBasic [
    #     {
    #       from.key_code = "right_command";
    #       to = [{ key_code = "right_option"; }];
    #     }
    #   ];
    # }

    # Function keys without holding fn (if you use them often)
    # {
    #   description = "Use F1-F12 as standard function keys";
    #   manipulators = allBasic (map (n: {
    #     from.key_code = "f${toString n}";
    #     to = [{ 
    #       key_code = "f${toString n}";
    #       modifiers = [ "fn" ];
    #     }];
    #   }) (lib.range 1 12));
    # }
  ];
in
{
  homebrew.casks = [ "karabiner-elements" ];

  home-manager.sharedModules = [{
    xdg.configFile."karabiner/karabiner.json".text = toJSON {
      global.show_in_menu_bar = false;

      profiles = [{
        inherit complex_modifications;

        name = "Default";
        selected = true;

        virtual_hid_keyboard.keyboard_type_v2 = "ansi";

        devices = [{
          inherit simple_modifications;
          identifiers.is_keyboard = true;
        }];
      }];
    };
  }];
}
