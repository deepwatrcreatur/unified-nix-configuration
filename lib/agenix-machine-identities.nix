let
  identityPath = "/var/lib/agenix/machine-identity";
  publicKeyDir = ../ssh-keys/agenix-machine-identities;

  readPublicKey =
    hostName:
    let
      keyPath = publicKeyDir + "/${hostName}.pub";
    in
    if builtins.pathExists keyPath then
      builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile keyPath)
    else
      null;
in
{
  inherit identityPath publicKeyDir readPublicKey;

  dashlaneItemName = hostName: "agenix machine identity - ${hostName}";
}
