# Home Assistant Alexa Manual Setup

This repo publishes Home Assistant externally at:

- `https://homeassistant.deepwatercreature.com`

The public TLS endpoint is terminated on `gateway` by Caddy and proxied to the
internal Home Assistant VM at `10.10.11.18:8123`.

## Repo-side pieces

- DNS/source-of-truth host entry: `lib/hosts.nix`
- Public reverse proxy and Cloudflare dynamic DNS: `hosts/nixos/gateway/caddy.nix`

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

Requirements:

- public HTTPS on port `443`
- trusted certificate
- Amazon Developer account
- AWS account / Lambda

This repo handles the public HTTPS side once `gateway` is rebuilt.
