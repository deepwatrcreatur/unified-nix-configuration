{ ... }:
{ config, pkgs, lib, ... }:
let
  secretKeyBaseFile = ../../secrets-agenix/roundtable-secret-key-base.age;
in
{
  imports = [
    ../../modules/nixos/services/roundtable.nix
  ];

  age.secrets."roundtable-secret-key-base" = lib.mkIf (builtins.pathExists secretKeyBaseFile) {
    file = secretKeyBaseFile;
  };

  age.secrets."anthropic-api-key" = {
    file = ../../secrets-agenix/anthropic-api-key.age;
  };

  age.secrets."openai-api-key" = {
    file = ../../secrets-agenix/openai-api-key.age;
  };

  age.secrets."gemini-api-key" = {
    file = ../../secrets-agenix/gemini-api-key.age;
  };

  age.secrets."deepseek-api-key" = {
    file = ../../secrets-agenix/deepseek-api-key.age;
  };

  services.roundtable = {
    enable = true;
    secretKeyBaseFile =
      if builtins.pathExists secretKeyBaseFile
      then config.age.secrets."roundtable-secret-key-base".path
      else null;
    # github-token-client aspect provides this at /run/secrets/github-token
    githubTokenFile = "/run/secrets/github-token";
    anthropicApiKeyFile = config.age.secrets."anthropic-api-key".path;
    openaiApiKeyFile = config.age.secrets."openai-api-key".path;
    geminiApiKeyFile = config.age.secrets."gemini-api-key".path;
    deepseekApiKeyFile = config.age.secrets."deepseek-api-key".path;
    oidcIssuerUrl = "https://authentik.deepwatercreature.com/application/o/roundtable/";
    phoenixHost = "roundtable.deepwatercreature.com";
  };

  environment.systemPackages = with pkgs; [
    dolt
  ];
}
