{ ... }:
{ config, pkgs, lib, ... }:
let
  secretKeyBaseFile = ../../secrets-agenix/roundtable-secret-key-base.age;
in
if builtins.pathExists secretKeyBaseFile then
  {
    imports = [
      ../../modules/nixos/services/roundtable.nix
    ];

    # The roundtable secret key base - needs to be created in secrets-agenix
    # We use a dedicated secret for the Phoenix application's SECRET_KEY_BASE
    age.secrets."roundtable-secret-key-base" = {
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
      secretKeyBaseFile = config.age.secrets."roundtable-secret-key-base".path;
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
else
  { }
