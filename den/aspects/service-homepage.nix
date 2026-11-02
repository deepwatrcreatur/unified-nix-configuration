# den/aspects/service-homepage.nix
# Central homelab landing page and dashboard (Homepage)
{ ... }:
{ ... }:
{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    openFirewall = true;
    allowedHosts = "homelab.deepwatercreature.com,10.10.11.69:8082,127.0.0.1:8082,localhost:8082";

    settings = {
      title = "Deepwater Homelab";
      header = "Deepwater Creature Homelab";
      theme = "dark";
      color = "slate";
      layout = {
        "Status & Infrastructure" = {
          style = "row";
          columns = 4;
        };
        "Core Applications" = {
          style = "row";
          columns = 4;
        };
        "Hypervisors & Storage" = {
          style = "row";
          columns = 3;
        };
      };
    };

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
    ];

    services = [
      {
        "Status & Infrastructure" = [
          {
            "Fleet Status" = {
              icon = "gatus.png";
              href = "https://status.deepwatercreature.com";
              description = "Automated fleet reachability & uptime monitor";
              widget = {
                type = "gatus";
                url = "http://127.0.0.1:8085";
              };
            };
          }
          {
            "Router Console" = {
              icon = "router.png";
              href = "https://dashboard.deepwatercreature.com";
              description = "nix-router-optimized hardware & firewall console";
              ping = "10.10.10.1";
            };
          }
          {
            "Technitium DNS" = {
              icon = "technitium-dns-server.png";
              href = "https://technitium.deepwatercreature.com";
              description = "Core network DNS server";
              ping = "10.10.10.1";
            };
          }
          {
            "Grafana" = {
              icon = "grafana.png";
              href = "https://grafana.deepwatercreature.com";
              description = "Telemetry & time-series dashboards";
              ping = "10.10.10.1";
            };
          }
        ];
      }
      {
        "Core Applications" = [
          {
            "Home Assistant" = {
              icon = "home-assistant.png";
              href = "https://home-assistant.deepwatercreature.com";
              description = "Home automation controller";
              ping = "10.10.11.84";
            };
          }
          {
            "Authentik" = {
              icon = "authentik.png";
              href = "https://authentik.deepwatercreature.com";
              description = "Identity provider & SSO gateway";
              ping = "10.10.11.70";
            };
          }
          {
            "Scrypted" = {
              icon = "scrypted.png";
              href = "https://scrypted.deepwatercreature.com";
              description = "Video streaming & NVR integration";
              ping = "10.10.11.85";
            };
          }
          {
            "Paperless-ngx" = {
              icon = "paperless-ngx.png";
              href = "https://paperless.deepwatercreature.com";
              description = "Document archiving system";
              ping = "10.10.11.84";
            };
          }
        ];
      }
      {
        "Hypervisors & Storage" = [
          {
            "Proxmox (ROG)" = {
              icon = "proxmox.png";
              href = "https://10.10.11.53:8006";
              description = "Primary compute & container hypervisor";
              ping = "10.10.11.53";
            };
          }
          {
            "Proxmox (Strix)" = {
              icon = "proxmox.png";
              href = "https://10.10.11.57:8006";
              description = "Secondary virtualization hypervisor";
              ping = "10.10.11.57";
            };
          }
          {
            "Synology DSM" = {
              icon = "synology.png";
              href = "https://synology.deepwatercreature.com";
              description = "Storage & backup management";
              ping = "10.10.11.88";
            };
          }
        ];
      }
    ];
  };
}
