{
  # Configure sops key file for decryption
  sops.age.keyFile = "/var/lib/sops/age/keys.txt";

  sops.secrets."attic-client-token" = {
    sopsFile = ../../../../secrets/attic-client-token.yaml.enc;
    key = "ATTIC_CLIENT_JWT_TOKEN";
    path = "/run/secrets/attic-client-token";
    owner = "root";
    mode = "0400";
  };
}
