{ ... }:
{ config, pkgs, ... }:
let
  secretPath = config.age.secrets."paperless-authentik-oidc".path;
  runtimeDir = "/var/lib/authentik/oidc/paperless";
  clientIdFile = "${runtimeDir}/client-id";
  clientSecretFile = "${runtimeDir}/client-secret";
in
{
  age.secrets."paperless-authentik-oidc" = {
    file = ../../secrets-agenix/paperless-authentik-oidc.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  systemd.tmpfiles.rules = [
    "d ${runtimeDir} 0750 authentik authentik -"
  ];

  systemd.services.authentik-prepare-paperless-oidc = {
    description = "Extract Paperless OIDC runtime credentials for Authentik";
    after = [ "agenix.service" ];
    before = [ "authentik-render-blueprints.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      Group = "root";
      ExecStart = pkgs.writeShellScript "authentik-prepare-paperless-oidc" ''
        set -euo pipefail

        install -d -m 0750 ${runtimeDir}

        ${pkgs.python3}/bin/python - <<'PY'
import json
import os
from pathlib import Path

source = Path("${secretPath}")
client_id_target = Path("${clientIdFile}")
client_secret_target = Path("${clientSecretFile}")

client_id = None
client_secret = None

for line in source.read_text().splitlines():
    if not line.startswith("PAPERLESS_SOCIALACCOUNT_PROVIDERS="):
        continue
    providers = json.loads(line.split("=", 1)[1])
    app = providers["openid_connect"]["APPS"][0]
    client_id = app["client_id"]
    client_secret = app["secret"]
    break

if not client_id or not client_secret:
    raise SystemExit("paperless-authentik-oidc secret is missing required OIDC fields")

old_umask = os.umask(0o377)
try:
    client_id_target.write_text(client_id)
    client_secret_target.write_text(client_secret)
finally:
    os.umask(old_umask)
PY

        chown authentik:authentik ${clientIdFile} ${clientSecretFile}
        chmod 0400 ${clientIdFile} ${clientSecretFile}
      '';
      ReadWritePaths = [ "/var/lib/authentik" ];
    };
  };

  services.authentik.applications.oidc.paperless = {
    slug = "paperless-ngx";
    displayName = "Paperless NGX";
    launchUrl = "https://paperless.deepwatercreature.com/";
    clientIdFile = clientIdFile;
    clientSecretFile = clientSecretFile;
    redirectUris = [
      "https://paperless.deepwatercreature.com/accounts/oidc/authentik/login/callback/"
    ];
  };
}
