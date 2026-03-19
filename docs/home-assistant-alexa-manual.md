# Home Assistant Alexa Manual Setup

This repo publishes Home Assistant externally at:

- `https://homeassistant.deepwatercreature.com`

The public TLS endpoint is terminated on `gateway` by Caddy and proxied to the
internal Home Assistant VM at `10.10.11.18:8123`.

## Repo-side pieces

- DNS/source-of-truth host entry: `lib/hosts.nix`
- Public reverse proxy and Cloudflare dynamic DNS: `hosts/nixos/gateway/caddy.nix`

## Cloudflare DNS

Use a `DNS only` Cloudflare `CNAME` record:

- name: `homeassistant`
- target: `homelab.deepwatercreature.com`

Do not create an `A` or `AAAA` record for `homeassistant`, and do not orange-cloud
the CNAME. This repo intentionally leaves `homeassistant` out of Caddy's
dynamic-DNS-managed names so the manual CNAME does not conflict with automatic
updates.

## Home Assistant reverse-proxy requirements

Home Assistant must trust the gateway reverse proxy or it may reject requests
with proxy-related HTTP errors.

In Home Assistant, ensure the HTTP integration allows forwarded headers from the
gateway LAN IP:

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

This repo handles the public HTTPS side once `gateway` is rebuilt and the
Cloudflare CNAME exists.

## Home Assistant configuration

Minimal HA YAML:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.10.10.1

alexa:
  smart_home:
    locale: en-CA
    endpoint: https://api.amazonalexa.com/v3/events
```

Adjust `locale` if your Alexa account is not using Canadian English. Home
Assistant's docs say `en-CA` still uses the `US East (N. Virginia)` Lambda
region.

Restart Home Assistant after editing `configuration.yaml`.

## Alexa Developer / AWS values

These values are now fixed by this repo's reverse-proxy setup:

- Home Assistant base URL: `https://homeassistant.deepwatercreature.com`
- Authorization URI: `https://homeassistant.deepwatercreature.com/auth/authorize`
- Access Token URI: `https://homeassistant.deepwatercreature.com/auth/token`

For AWS Lambda:

- region for `en-US` / `en-CA`: `US East (N. Virginia)`
- `BASE_URL` environment variable:
  `https://homeassistant.deepwatercreature.com`

For Home Assistant's manual Alexa integration, the default proactive-events
endpoint for North America is:

- `https://api.amazonalexa.com/v3/events`

## Sequence

1. Create the Cloudflare `DNS only` CNAME for `homeassistant`.
2. Rebuild `gateway` so Caddy serves `homeassistant.deepwatercreature.com`.
3. Verify `https://homeassistant.deepwatercreature.com` presents a valid public
   certificate.
4. Add the `http:` and `alexa:` configuration to Home Assistant and restart it.
5. Create the Alexa Smart Home skill and AWS Lambda function using the official
   Home Assistant guide.
6. Link the skill in the Alexa app and discover devices.
