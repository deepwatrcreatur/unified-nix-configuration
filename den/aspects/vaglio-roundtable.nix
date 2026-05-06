{ ... }:
{ config, lib, ... }:
let
  secretKeyBaseFile = ../../secrets-agenix/roundtable-secret-key-base.age;
in
if builtins.pathExists secretKeyBaseFile then
  {
    imports = [
      ../../modules/nixos/services/roundtable.nix
    ];

    age.secrets."roundtable-secret-key-base" = {
      file = secretKeyBaseFile;
      path = "/run/secrets/roundtable-secret-key-base";
      owner = "deepwatrcreatur";
      mode = "0400";
    };

    services.roundtable = {
      enable = true;
      workingDirectory = "/var/lib/roundtable";
      secretKeyBaseFile = config.age.secrets."roundtable-secret-key-base".path;
      githubTokenFile = "/run/secrets/github-token";
      oidcIssuerUrl = "https://authentik.deepwatercreature.com/application/o/roundtable/";
      phoenixHost = "roundtable.deepwatercreature.com";
      discussionRepo = "deepwatrcreatur/agent-roundtable-design";
      discussionBriefPath = "BRIEF.md";
    };
  }
else
  { }
