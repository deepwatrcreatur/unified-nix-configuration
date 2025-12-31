{
  # Configure sops key file for decryption
  sops.age.keyFile = "/var/lib/sops/age/keys.txt";

  # RustDesk server secrets can be added here as needed
  # Example:
  # sops.secrets."rustdesk/hkey" = {
  #   sopsFile = ../../../../secrets/rustdesk-secrets.yaml.enc;
  #   key = "HKEY";
  #   path = "/run/secrets/rustdesk-hkey";
  #   owner = "rustdesk";
  #   mode = "0400";
  # };
}
