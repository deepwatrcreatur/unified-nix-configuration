{
  description = "Zellij configuration with Catppuccin theme, extended layout, and Ctrl-Alt keybindings";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    homeManagerModules.default = import ./module.nix;
  };
}