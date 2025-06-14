# users/deepwatrcreatur/sops.nix
{ config, lib, pkgs, ... }: # Add 'inputs' here if your flake passes it

let
  # Path to your shared secrets directory relative to the flake root
  # This makes it robust regardless of where home-manager config is located.
  sopsSecretsDir = toString (builtins.path { path = ../../users/deepwatrcreatur/secrets;});
in
{
  # Define an option to enable/disable this module
  options.my.sops.enable = lib.mkEnableOption "Sops integration for home-manager";

  config = lib.mkIf config.my.sops.enable {
    # Import sops-nix Home Manager module
    # This enables `config.sops.secrets` for home-manager.
    # It must come from the `sops-nix` flake input.
    imports = [ inputs.sops-nix.homeManagerModules.sops ];

    # Ensure the sops binary is available in the user's path
    home.packages = [ pkgs.sops ];

    # Declaratively manage the .sops.yaml file
    # This will place it in ~/.config/sops/.sops.yaml by default (XDG compliant)
    home.file."${config.xdg.configHome}/sops/.sops.yaml" = {
      source = "${sopsSecretsDir}/.sops.yaml";
      # You might want to ensure it's read-only for security
      mode = "0400";
    };

    # an encrypted file like secrets/user-secrets/gpg-keys.yaml.enc
    #sops.secrets.gpg-ssh-keys = {
      #sopsFile = "${sopsSecretsDir}/gpg-keys.yaml.enc";
      # The key within the YAML file if you have multiple keys
      # Example: gpg_signing_key: "..."
      #key = "gpg_signing_key"; # Adjust based on your encrypted YAML structure
      # Path where the decrypted GPG key will be placed for user
      # You might need to adjust this path based on how GPG is configured
      # ~/.gnupg is often managed by a separate GPG Home Manager module.
      # A common pattern is to just decrypt to a temporary location
      # and then import the key, or use a tool that directly uses the file.
      #path = "${config.xdg.configHome}/gpg/signing_key"; # Example path, adjust
      #mode = "0600";
  };
}
