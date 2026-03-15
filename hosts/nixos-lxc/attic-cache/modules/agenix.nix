{
  # Agenix configuration for attic-cache
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  age.secrets."attic-client-token" = {
    file = ../../../../secrets-agenix/attic-client-token.age;
    path = "/run/secrets/attic-client-token";
    owner = "root";
    mode = "0400";
  };

  age.secrets."attic-server-token" = {
    file = ../../../../secrets-agenix/attic-server-token.age;
    path = "/run/secrets/attic-server-token";
    owner = "root";
    mode = "0400";
  };

  age.secrets."attic-jwt-secret" = {
    file = ../../../../secrets-agenix/attic-jwt-secret.age;
    path = "/run/secrets/attic-jwt-secret";
    owner = "root";
    mode = "0400";
  };
}
