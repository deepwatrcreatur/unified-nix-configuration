# Home Assistant Alexa Manual Setup

This repo publishes Home Assistant externally at:

- `https://home-assistant.deepwatercreature.com`

The public TLS endpoint is terminated on `router` by Caddy and proxied to the
internal Home Assistant VM at `10.10.11.18:8123`.

Keep the direct host record and the public proxy hostname separate:

- `homeassistant.deepwatercreature.com` -> direct VM address from DHCP/DNS
- `home-assistant.deepwatercreature.com` -> public Caddy endpoint on `router`

## Repo-side pieces

- DNS/source-of-truth host entry: `lib/hosts.nix`
- Public reverse proxy and Cloudflare dynamic DNS: `hosts/nixos/router/caddy.nix`

## Cloudflare DNS

Use a `DNS only` Cloudflare `CNAME` record:

- name: `home-assistant`
- target: `homelab.deepwatercreature.com`

Do not create an `A` or `AAAA` record for `home-assistant`, and do not orange-cloud
the CNAME. This repo intentionally leaves `home-assistant` out of Caddy's
dynamic-DNS-managed names so the manual CNAME does not conflict with automatic
updates.

## Home Assistant reverse-proxy requirements

Home Assistant must trust the router reverse proxy or it may reject requests
with proxy-related HTTP errors.

In Home Assistant, ensure the HTTP integration allows forwarded headers from the
router LAN IP:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.10.10.1
```

If Home Assistant is configured through the UI instead of YAML, set the
equivalent reverse-proxy trust there.

## Manual Alexa replacement for HA Cloud

Use Home Assistant's manual Alexa Smart Home integration:

- Home Assistant docs: `https://www.home-assistant.io/integrations/alexa.smart_home/`
- Base Alexa integration docs: `https://www.home-assistant.io/integrations/alexa/`
- Reverse proxy / trusted proxy docs: `https://www.home-assistant.io/integrations/http/`

Requirements:

- public HTTPS on port `443`
- trusted certificate
- Amazon Developer account
- AWS account / Lambda

This repo handles the public HTTPS side once `router` is rebuilt and the
Cloudflare CNAME exists.

## Home Assistant configuration

Minimal first-working HA YAML:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.10.10.1

alexa:
  smart_home:
    locale: en-CA
```

Adjust `locale` if your Alexa account is not using Canadian English. Home
Assistant's docs say `en-CA` still uses the `US East (N. Virginia)` Lambda
region.

Restart Home Assistant after editing `configuration.yaml`.

## AWS and Alexa console values

Start with the basic Smart Home flow first. Do not enable proactive events
until discovery and normal voice control are working.

These values are now fixed by this repo's reverse-proxy setup:

- Home Assistant base URL: `https://home-assistant.deepwatercreature.com`
- Authorization URI: `https://home-assistant.deepwatercreature.com/auth/authorize`
- Access Token URI: `https://home-assistant.deepwatercreature.com/auth/token`

### Amazon Developer Console

Create a skill with:

- Skill type: `Smart Home`
- Provisioning: `Provision your own`
- Payload version: `v3`

Keep the generated `Skill ID`; AWS Lambda needs it as a trigger binding.

### AWS Lambda

For `en-CA` / `en-US`, Home Assistant's docs require:

- AWS region: `US East (N. Virginia)` / `us-east-1`

Create:

- IAM role: `Lambda` service role with `AWSLambdaBasicExecutionRole`
- Lambda runtime: current `Python 3.x`
- Lambda trigger: `Alexa Smart Home`
- Trigger Skill ID: the `Skill ID` from the Alexa Developer Console

Set Lambda environment variables:

- region for `en-US` / `en-CA`: `US East (N. Virginia)`
- `BASE_URL` environment variable:
  `https://home-assistant.deepwatercreature.com`

Optional for testing only:

- `DEBUG=True`
- `LONG_LIVED_ACCESS_TOKEN=<temporary HA long-lived token>`

Remove `LONG_LIVED_ACCESS_TOKEN` after testing.

The Home Assistant docs currently point to this Lambda source:

- `https://gist.github.com/matt2005/744b5ef548cc13d88d0569eea65f5e5b`

### Alexa account linking

In the skill's `ACCOUNT LINKING` section:

- Grant type: `Auth Code Grant`
- Authorization URI:
  `https://home-assistant.deepwatercreature.com/auth/authorize`
- Access Token URI:
  `https://home-assistant.deepwatercreature.com/auth/token`

For `Client ID`, Home Assistant's docs specify:

- `https://pitangui.amazon.com/` for US/BR
- `https://layla.amazon.com/` for EU
- `https://alexa.amazon.co.jp/` for JP/AU

For Canadian English, use the North America setup:

- Lambda region: `us-east-1`
- `Client ID`: `https://pitangui.amazon.com/`

Other required fields:

- `Client Secret`: any placeholder string
- `Your Authentication Scheme`: `Credentials in request body`
- `Scope`: `smart_home`

Leave empty unless the console requires otherwise:

- `Domain List`
- `Default Access Token Expiration Time`

### Optional proactive events

Only after normal discovery/control works, you can add proactive events.

For Home Assistant's Alexa integration, the North America proactive-events
endpoint is:

- `https://api.amazonalexa.com/v3/events`

To use proactive events, Home Assistant's docs say you also need `client_id`
and `client_secret` from the Alexa Developer Console's `Alexa Skill Messaging`
permission flow, not the placeholder account-linking values above.

At that point, extend HA config to:

```yaml
alexa:
  smart_home:
    locale: en-CA
    endpoint: https://api.amazonalexa.com/v3/events
    client_id: YOUR_ALEXA_SKILL_MESSAGING_CLIENT_ID
    client_secret: YOUR_ALEXA_SKILL_MESSAGING_CLIENT_SECRET
```

If you enable `Send Alexa Events` later, you may need to unlink and relink the
skill in Alexa.

## Test sequence

1. Verify the public endpoint:
   `curl -I https://home-assistant.deepwatercreature.com`
2. Create the Smart Home skill in the Alexa Developer Console.
3. Create the Lambda role and Lambda function in `us-east-1`.
4. Paste the Home Assistant Lambda Python code from the official HA docs/gist.
5. Set `BASE_URL=https://home-assistant.deepwatercreature.com`.
6. Add the Alexa Smart Home trigger using the skill's `Skill ID`.
7. Optionally set `DEBUG=True` and `LONG_LIVED_ACCESS_TOKEN` to test discovery
   in Lambda before account linking.
8. Put the Lambda ARN into the skill's Smart Home endpoint section.
9. Configure account linking with the HA auth/token URLs above.
10. In the Alexa app, open `Your Skills -> Dev`, enable the skill, log into Home
    Assistant, and let Alexa discover devices.

## Sequence

1. Create the Cloudflare `DNS only` CNAME for `home-assistant`.
2. Rebuild `router` so Caddy serves `home-assistant.deepwatercreature.com`.
3. Verify `https://home-assistant.deepwatercreature.com` presents a valid public
   certificate.
4. Add the `http:` and minimal `alexa:` configuration to Home Assistant and
   restart it.
5. Create the Alexa Smart Home skill and AWS Lambda function in `us-east-1`.
6. Configure account linking to Home Assistant.
7. Link the skill in the Alexa app and discover devices.
8. Only after that, decide whether you want proactive events.
