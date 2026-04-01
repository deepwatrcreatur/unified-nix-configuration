# Paperless + Authentik Setup

This repo now deploys:

- `authentik.deepwatercreature.com` on `homeserver`
- `paperless.deepwatercreature.com` on `podman`
- public ingress for both via `router` Caddy

## First Deploy

Deploy these hosts in this order:

1. `homeserver`
2. `router`
3. `podman`

Authentik will be reachable at `https://authentik.deepwatercreature.com`.

## Authentik First Login

The `authentik-env` secret bootstraps the `akadmin` account on first startup.

After deploy:

1. Open `https://authentik.deepwatercreature.com`
2. Log in as `akadmin`
3. Change the bootstrap password
4. Rotate or delete the bootstrap token once setup is complete

## Create the Paperless OIDC Application

In Authentik:

1. Go to Applications > Applications
2. Click Create with Provider
3. Choose OAuth2/OpenID Connect
4. Set a strict redirect URI to `https://paperless.deepwatercreature.com/accounts/oidc/authentik/login/callback/`
5. Add these scopes:
   - `openid`
   - `email`
   - `profile`
6. Note the generated Client ID, Client Secret, and application slug

## Create the Paperless OIDC Secret

Create `secrets-agenix/paperless-authentik-oidc.age` with these contents:

```env
PAPERLESS_APPS=allauth.socialaccount.providers.openid_connect
PAPERLESS_SOCIALACCOUNT_PROVIDERS={"openid_connect":{"APPS":[{"provider_id":"authentik","name":"Authentik","client_id":"<client-id>","secret":"<client-secret>","settings":{"server_url":"https://authentik.deepwatercreature.com/application/o/<slug>/.well-known/openid-configuration"}}],"OAUTH_PKCE_ENABLED":"True"}}
```

Then deploy `podman` again.

## Linking Existing Paperless Users

Paperless local login is intentionally still enabled.

To attach Authentik to an existing Paperless account:

1. Log in to Paperless with the existing local account
2. Open My Profile
3. Use Connect new social account
4. Link the Authentik login

After you confirm SSO works, you can choose to disable regular Paperless login in a later change.
