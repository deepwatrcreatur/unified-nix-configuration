
# modules/home-manager/helix-config.nix
{ config, pkgs, lib, inputs, ... }: # Ensure 'inputs' is here

{
  programs.helix = {
    enable = true;
    # Use the package from the Helix flake input
    package = inputs.helix.packages.${pkgs.system}.helix;
    defaultEditor = true; 
    extraPackages = with pkgs; [
      nil
      nixd
      nixpkgs-fmt
      elixir-ls
    ];
    settings = import ./settings.nix;
    languages = import ./languages.nix { inherit pkgs; };
  };
}
