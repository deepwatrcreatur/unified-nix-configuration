`homeserver` is the dedicated Homebridge host at `10.10.11.69`.

Notes:
- This deploys native NixOS `services.homebridge`, including `homebridge-config-ui-x` on port `8581`.
- HomeKit pairing traffic stays on the LAN via Homebridge itself; the web UI is local to the host unless you later proxy it from `gateway`.
- `https://www.homebridge.ca/registerWelcome` is part of the cloud flow used by some third-party Homebridge plugins, especially Alexa integrations. This host gives you the self-hosted Homebridge service, not a self-hosted replacement for Amazon or Homebridge vendor cloud account-linking.
