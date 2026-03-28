{ ... }:
{ config, pkgs, ... }:
let
  secretPath = config.age.secrets."paperless-authentik-oidc".path;
in
{
  age.secrets."paperless-authentik-oidc" = {
    file = ../../secrets-agenix/paperless-authentik-oidc.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  services.authentik.blueprints.rendered.paperless = {
    fileName = "paperless-ngx.yaml";
    script = ''
      ${pkgs.python3}/bin/python - <<'PY'
import json
import os
import textwrap
from pathlib import Path

source = Path("${secretPath}")
target = Path(os.environ["AUTHENTIK_BLUEPRINT_OUTPUT"])

client_id = None
client_secret = None
server_url = None

for line in source.read_text().splitlines():
    if not line.startswith("PAPERLESS_SOCIALACCOUNT_PROVIDERS="):
        continue
    providers = json.loads(line.split("=", 1)[1])
    app = providers["openid_connect"]["APPS"][0]
    client_id = app["client_id"]
    client_secret = app["secret"]
    server_url = app["settings"]["server_url"]
    break

if not client_id or not client_secret or not server_url:
    raise SystemExit("paperless-authentik-oidc secret is missing required OIDC fields")

if "/application/o/" not in server_url:
    raise SystemExit(f"unexpected Authentik server_url format: {server_url}")

application_slug = server_url.split("/application/o/", 1)[1].split("/", 1)[0]
callback_url = "https://paperless.deepwatercreature.com/accounts/oidc/authentik/login/callback/"

target.write_text(
    textwrap.dedent(
        f"""\
version: 1
metadata:
  name: Paperless NGX
entries:
  - model: authentik_providers_oauth2.oauth2provider
    id: paperless_provider
    identifiers:
      name: {application_slug}
    attrs:
      authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
      invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]
      client_type: confidential
      client_id: {client_id}
      client_secret: {client_secret}
      redirect_uris:
        - matching_mode: strict
          url: {callback_url}
      property_mappings:
        - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-openid]]
        - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-email]]
        - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-profile]]
        - !Find [authentik_providers_oauth2.scopemapping, [managed, goauthentik.io/providers/oauth2/scope-offline_access]]
      signing_key: !Find [authentik_crypto.certificatekeypair, [name, authentik Self-signed Certificate]]
  - model: authentik_core.application
    identifiers:
      slug: {application_slug}
    attrs:
      provider: !KeyOf paperless_provider
      name: Paperless NGX
      meta_launch_url: https://paperless.deepwatercreature.com/
"""
    )
)
PY
    '';
  };
}
