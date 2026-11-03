# den/aspects/authentik-proxy-forward-auth.nix
# Declarative Authentik Proxy Providers and Applications for Homelab and Status
{ ... }:
{ ... }:
{
  services.authentik.blueprints.files."proxy-forward-auth.yaml" = ''
    version: 1
    metadata:
      name: Homelab and Status Forward Auth Providers
    entries:
      - model: authentik_providers_proxy.proxyprovider
        id: homelab_provider
        identifiers:
          name: homelab-proxy
        attrs:
          authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
          invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]
          mode: forward_single
          external_host: https://homelab.deepwatercreature.com
      - model: authentik_core.application
        identifiers:
          slug: homelab
        attrs:
          provider: !KeyOf homelab_provider
          name: Homelab Dashboard
          meta_launch_url: https://homelab.deepwatercreature.com/
      - model: authentik_providers_proxy.proxyprovider
        id: status_provider
        identifiers:
          name: status-proxy
        attrs:
          authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
          invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]
          mode: forward_single
          external_host: https://status.deepwatercreature.com
      - model: authentik_core.application
        identifiers:
          slug: status
        attrs:
          provider: !KeyOf status_provider
          name: Fleet Status (Gatus)
          meta_launch_url: https://status.deepwatercreature.com/
      - model: authentik_outposts.outpost
        identifiers:
          name: authentik Embedded Outpost
        attrs:
          providers:
            - !KeyOf homelab_provider
            - !KeyOf status_provider
  '';
}
