# Router web dashboards and monitoring
{ config, pkgs, lib, ... }:

{
  # vnStat for traffic statistics and graphs
  services.vnstat.enable = true;

  # Prometheus for metrics collection
  services.prometheus = {
    enable = true;
    port = 9090;
    
    # Scrape local node exporter
    scrapeConfigs = [
      {
        job_name = "gateway";
        static_configs = [{
          targets = [ "127.0.0.1:9100" ];
        }];
      }
      {
        job_name = "node";
        static_configs = [{
          targets = [ "127.0.0.1:9100" ];
        }];
      }
    ];
    
    # Retention
    retentionTime = "30d";
  };

  # Prometheus Node Exporter for system metrics
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [
      "systemd"
      "processes"
      "network_route"
      "ntp"
      "conntrack"
      "netstat"
      "tcpstat"
    ];
  };

  # Prometheus Blackbox Exporter for ping/latency monitoring
  services.prometheus.exporters.blackbox = {
    enable = true;
    port = 9115;
    configFile = pkgs.writeText "blackbox.yml" ''
      modules:
        icmp_ipv4:
          prober: icmp
          timeout: 5s
          icmp:
            preferred_ip_protocol: ip4
        icmp_ipv6:
          prober: icmp
          timeout: 5s
          icmp:
            preferred_ip_protocol: ip6
        http_2xx:
          prober: http
          timeout: 5s
          http:
            preferred_ip_protocol: ip4
    '';
  };

  # Grafana for beautiful dashboards
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        domain = "gateway.deepwatercreature.com";
        root_url = "%(protocol)s://%(domain)s:%(http_port)s/";
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{/var/lib/grafana/secrets/admin-password}";
      };
      analytics.reporting_enabled = false;
    };
    
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:9090";
          isDefault = true;
        }
      ];
      
      dashboards.settings.providers = [
        {
          name = "Gateway Dashboards";
          type = "file";
          options.path = "/etc/grafana-dashboards";
        }
      ];
    };
  };

  # Grafana admin password (using simple file-based secret)
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana/secrets 0750 grafana grafana -"
    "f /var/lib/grafana/secrets/admin-password 0640 grafana grafana - admin"
  ];

  # Install router monitoring packages
  environment.systemPackages = with pkgs; [
    vnstat                # Traffic statistics
    bandwhich             # Real-time bandwidth monitor by process
    speedtest-cli         # Internet speed testing
    nethogs               # Per-process bandwidth monitor
    iftop                 # Real-time interface bandwidth
    nload                 # Network load visualizer
    bmon                  # Bandwidth monitor
    jnettop               # Network traffic visualizer
  ];

  # Netdata for real-time system monitoring
  services.netdata = {
    enable = true;
    config = {
      global = {
        "default port" = "19999";
        "bind to" = "*";
        "memory mode" = "dbengine";
        "page cache size" = "32";
      };
      web = {
        "allow connections from" = "*";
        "allow dashboard from" = "*";
      };
    };
  };

  # Custom router dashboard script
  environment.etc."router-dashboard/index.html" = {
    text = ''
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Gateway Router Dashboard</title>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            color: #e2e8f0;
            padding: 20px;
            min-height: 100vh;
          }
          .container { max-width: 1600px; margin: 0 auto; }
          header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
            padding-bottom: 1rem;
            border-bottom: 2px solid #1e40af;
          }
          h1 {
            font-size: 2.5rem;
            color: #60a5fa;
            display: flex;
            align-items: center;
            gap: 0.5rem;
          }
          .last-update {
            color: #94a3b8;
            font-size: 0.9rem;
          }
          .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
          }
          .card {
            background: rgba(30, 41, 59, 0.8);
            border-radius: 12px;
            padding: 24px;
            border: 1px solid #334155;
            backdrop-filter: blur(10px);
            transition: transform 0.2s, border-color 0.2s;
          }
          .card:hover {
            transform: translateY(-2px);
            border-color: #60a5fa;
          }
          .card h2 {
            font-size: 1.3rem;
            margin-bottom: 1rem;
            color: #93c5fd;
            display: flex;
            align-items: center;
            gap: 0.5rem;
          }
          .metric {
            margin: 12px 0;
            padding: 8px;
            border-radius: 6px;
            background: rgba(15, 23, 42, 0.5);
          }
          .metric-label {
            color: #94a3b8;
            font-size: 0.85rem;
            margin-bottom: 4px;
          }
          .metric-value {
            font-size: 1.4rem;
            font-weight: 600;
            color: #60a5fa;
            font-variant-numeric: tabular-nums;
          }
          .metric-small .metric-value {
            font-size: 1.1rem;
          }
          .links {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
            gap: 12px;
          }
          .link-btn {
            background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%);
            color: white;
            padding: 14px 20px;
            border-radius: 8px;
            text-decoration: none;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: all 0.2s;
            font-weight: 500;
            text-align: center;
          }
          .link-btn:hover {
            background: linear-gradient(135deg, #2563eb 0%, #60a5fa 100%);
            transform: scale(1.05);
            box-shadow: 0 4px 20px rgba(59, 130, 246, 0.4);
          }
          .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 500;
          }
          .status-up {
            background: rgba(16, 185, 129, 0.2);
            color: #10b981;
            border: 1px solid #10b981;
          }
          .status-down {
            background: rgba(239, 68, 68, 0.2);
            color: #ef4444;
            border: 1px solid #ef4444;
          }
          .status-warning {
            background: rgba(245, 158, 11, 0.2);
            color: #f59e0b;
            border: 1px solid #f59e0b;
          }
          .progress-bar {
            width: 100%;
            height: 8px;
            background: #1e293b;
            border-radius: 4px;
            overflow: hidden;
            margin-top: 8px;
          }
          .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #3b82f6, #60a5fa);
            transition: width 0.3s ease;
          }
          .interface-card {
            border-left: 4px solid #3b82f6;
          }
          .wan-card { border-left-color: #10b981; }
          .lan-card { border-left-color: #60a5fa; }
          .mgmt-card { border-left-color: #f59e0b; }
          @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
          }
          .loading {
            animation: pulse 1.5s ease-in-out infinite;
          }
          .stat-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <header>
            <h1>🌐 Gateway Router</h1>
            <div class="last-update" id="lastUpdate">Loading...</div>
          </header>
          
          <div class="grid">
            <!-- Quick Links -->
            <div class="card">
              <h2>🔗 Quick Links</h2>
              <div class="links">
                <a href="http://gateway:19999" class="link-btn" target="_blank">📊 Netdata</a>
                <a href="http://gateway:3000" class="link-btn" target="_blank">📈 Grafana</a>
                <a href="http://gateway:5380" class="link-btn" target="_blank">🌍 DNS</a>
                <a href="http://gateway:81" class="link-btn" target="_blank">🔀 Proxy</a>
                <a href="http://gateway:9090" class="link-btn" target="_blank">🎯 Metrics</a>
              </div>
            </div>
            
            <!-- WAN Interface -->
            <div class="card interface-card wan-card" id="wan-card">
              <h2>🌍 WAN (ens17)</h2>
              <div class="metric">
                <div class="metric-label">Status</div>
                <span class="status-badge status-up" id="wan-status">● UP</span>
              </div>
              <div class="metric metric-small">
                <div class="metric-label">IPv4 Address</div>
                <div class="metric-value" id="wan-ipv4">Loading...</div>
              </div>
              <div class="stat-grid">
                <div class="metric metric-small">
                  <div class="metric-label">RX</div>
                  <div class="metric-value" id="wan-rx">-</div>
                </div>
                <div class="metric metric-small">
                  <div class="metric-label">TX</div>
                  <div class="metric-value" id="wan-tx">-</div>
                </div>
              </div>
            </div>
            
            <!-- LAN Interface -->
            <div class="card interface-card lan-card" id="lan-card">
              <h2>🏠 LAN (ens16)</h2>
              <div class="metric">
                <div class="metric-label">Status</div>
                <span class="status-badge status-up" id="lan-status">● UP</span>
              </div>
              <div class="metric metric-small">
                <div class="metric-label">IPv4 Address</div>
                <div class="metric-value" id="lan-ipv4">10.10.10.1</div>
              </div>
              <div class="stat-grid">
                <div class="metric metric-small">
                  <div class="metric-label">RX</div>
                  <div class="metric-value" id="lan-rx">-</div>
                </div>
                <div class="metric metric-small">
                  <div class="metric-label">TX</div>
                  <div class="metric-value" id="lan-tx">-</div>
                </div>
              </div>
            </div>
            
            <!-- Management Interface -->
            <div class="card interface-card mgmt-card" id="mgmt-card">
              <h2>🔧 Management (ens18)</h2>
              <div class="metric">
                <div class="metric-label">Status</div>
                <span class="status-badge status-up" id="mgmt-status">● UP</span>
              </div>
              <div class="metric metric-small">
                <div class="metric-label">IPv4 Address</div>
                <div class="metric-value" id="mgmt-ipv4">192.168.100.100</div>
              </div>
              <div class="stat-grid">
                <div class="metric metric-small">
                  <div class="metric-label">RX</div>
                  <div class="metric-value" id="mgmt-rx">-</div>
                </div>
                <div class="metric metric-small">
                  <div class="metric-label">TX</div>
                  <div class="metric-value" id="mgmt-tx">-</div>
                </div>
              </div>
            </div>
            
            <!-- Connection Tracking -->
            <div class="card">
              <h2>🔌 Connections</h2>
              <div class="metric">
                <div class="metric-label">Active Connections</div>
                <div class="metric-value" id="conn-count">-</div>
              </div>
              <div class="metric">
                <div class="metric-label">Capacity</div>
                <div class="metric-value" id="conn-max">262,144</div>
                <div class="progress-bar">
                  <div class="progress-fill" id="conn-progress" style="width: 0%"></div>
                </div>
              </div>
            </div>
            
            <!-- System Info -->
            <div class="card">
              <h2>💻 System</h2>
              <div class="metric metric-small">
                <div class="metric-label">Hostname</div>
                <div class="metric-value" id="hostname">gateway</div>
              </div>
              <div class="metric metric-small">
                <div class="metric-label">Uptime</div>
                <div class="metric-value" id="uptime">-</div>
              </div>
            </div>
          </div>
          
          <div class="card">
            <h2>📚 Features</h2>
            <div style="color: #cbd5e1; line-height: 1.8;">
              <strong style="color: #60a5fa;">⚡ Performance:</strong> nftables flowtable offload, BBR congestion control, CAKE QoS<br>
              <strong style="color: #60a5fa;">🛡️ Security:</strong> Stateful firewall, fail2ban, connection tracking<br>
              <strong style="color: #60a5fa;">📊 Monitoring:</strong> Netdata, Grafana, Prometheus, vnStat traffic analysis<br>
              <strong style="color: #60a5fa;">🔧 Hardware:</strong> TSO/GSO/GRO offload, IRQ balancing, optimized buffers
            </div>
          </div>
        </div>
        
        <script>
          async function updateStats() {
            try {
              const response = await fetch('/api/status');
              const data = await response.json();
              
              // Update timestamp
              document.getElementById('lastUpdate').textContent = 
                'Last updated: ' + new Date(data.timestamp).toLocaleTimeString();
              
              // Update WAN
              updateInterface('wan', data.interfaces.wan);
              
              // Update LAN
              updateInterface('lan', data.interfaces.lan);
              
              // Update Management
              updateInterface('mgmt', data.interfaces.mgmt);
              
              // Update connections
              const connPct = (data.connections.tracked / data.connections.max * 100).toFixed(1);
              document.getElementById('conn-count').textContent = 
                data.connections.tracked.toLocaleString();
              document.getElementById('conn-max').textContent = 
                data.connections.max.toLocaleString();
              document.getElementById('conn-progress').style.width = connPct + '%';
              
              // Update system
              document.getElementById('hostname').textContent = data.hostname;
              document.getElementById('uptime').textContent = data.uptime;
              
            } catch (error) {
              console.error('Failed to fetch stats:', error);
              document.getElementById('lastUpdate').textContent = 
                'Error: ' + error.message;
            }
          }
          
          function updateInterface(prefix, ifdata) {
            const statusEl = document.getElementById(prefix + '-status');
            if (ifdata.state === 'UP') {
              statusEl.className = 'status-badge status-up';
              statusEl.textContent = '● UP';
            } else {
              statusEl.className = 'status-badge status-down';
              statusEl.textContent = '● DOWN';
            }
            
            document.getElementById(prefix + '-ipv4').textContent = ifdata.ipv4;
            document.getElementById(prefix + '-rx').textContent = ifdata.stats.rx_bytes_human;
            document.getElementById(prefix + '-tx').textContent = ifdata.stats.tx_bytes_human;
          }
          
          // Update immediately and then every 5 seconds
          updateStats();
          setInterval(updateStats, 5000);
        </script>
      </body>
      </html>
    '';
  };

  # API endpoint for status
  environment.etc."router-dashboard/api/status".source = 
    pkgs.writeShellScript "network-status-api" ''
      exec ${pkgs.bash}/bin/bash /etc/router-dashboard/network-status.sh
    '';

  # Network status script
  environment.etc."router-dashboard/network-status.sh" = {
    text = builtins.readFile ./scripts/network-status.sh;
    mode = "0755";
  };

  # Simple HTTP server for the dashboard with API support
  systemd.services.router-dashboard = {
    description = "Router Dashboard Web Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      ExecStart = "${pkgs.writeShellScript "router-dashboard-server" ''
        cd /etc/router-dashboard
        ${pkgs.python3}/bin/python3 -m http.server 8080 --bind 0.0.0.0
      ''}";
      Restart = "always";
    };
  };

  # Create systemd timer for vnstat database update
  systemd.timers.vnstat-update = {
    description = "Update vnStat database";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
    };
  };

  systemd.services.vnstat-update = {
    description = "Update vnStat database";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.vnstat}/bin/vnstat -u";
    };
  };
}
