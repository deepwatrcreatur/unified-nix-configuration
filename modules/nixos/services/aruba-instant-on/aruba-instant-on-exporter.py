import base64
import hashlib
import json
import logging
import os
import re
import sys
import time
from prometheus_client import start_http_server, Gauge

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s'
)
logger = logging.getLogger('aruba-instant-on-exporter')

# Metrics Definitions
AIO_UP = Gauge('aruba_instant_on_up', 'Aruba Instant On exporter scrape status (1 = success, 0 = failed)')
AIO_SITES_TOTAL = Gauge('aruba_instant_on_sites_total', 'Total number of managed Aruba Instant On sites')

# Device (AP) Metrics
AIO_DEVICE_STATUS = Gauge('aruba_instant_on_device_status', 'Device status (1 = Online, 0 = Offline)', ['site', 'name', 'model', 'serial', 'mac', 'ip'])
AIO_DEVICE_CLIENTS = Gauge('aruba_instant_on_device_clients', 'Connected clients per device', ['site', 'name', 'model', 'mac'])

# Client Metrics
AIO_CLIENT_CONNECTED = Gauge('aruba_instant_on_client_connected', 'Connected wireless client status (1 = connected)', ['site', 'name', 'mac', 'ip', 'ap', 'ssid', 'band'])
AIO_CLIENT_RSSI = Gauge('aruba_instant_on_client_rssi_dbm', 'Client Wi-Fi signal strength RSSI in dBm', ['site', 'name', 'mac', 'ap', 'ssid'])
AIO_CLIENT_TX_RATE = Gauge('aruba_instant_on_client_tx_rate_mbps', 'Client PHY TX rate in Mbps', ['site', 'name', 'mac', 'ap'])
AIO_CLIENT_RX_RATE = Gauge('aruba_instant_on_client_rx_rate_mbps', 'Client PHY RX rate in Mbps', ['site', 'name', 'mac', 'ap'])
AIO_CLIENTS_TOTAL = Gauge('aruba_instant_on_clients_total', 'Total active Wi-Fi clients in site', ['site'])

# Network / SSID Metrics
AIO_NETWORK_CLIENTS = Gauge('aruba_instant_on_network_clients', 'Client count per SSID', ['site', 'ssid'])

# Alert Metrics
AIO_ALERTS_OPEN = Gauge('aruba_instant_on_alerts_open', 'Open alert count', ['site'])

class ArubaInstantOnClient:
    def __init__(self, username, password):
        self.username = username
        self.password = password
        self.access_token = None
        self.token_expiry = 0

    def authenticate(self):
        import requests

        code_verifier = base64.urlsafe_b64encode(os.urandom(43)).decode('utf-8')
        code_verifier = re.sub(r'[^a-zA-Z0-9]+', '', code_verifier)

        state = base64.urlsafe_b64encode(os.urandom(43)).decode('utf-8')
        state = re.sub(r'[^a-zA-Z0-9]+', '', state)

        code_challenge = hashlib.sha256(code_verifier.encode('utf-8')).digest()
        code_challenge = base64.urlsafe_b64encode(code_challenge).decode('utf-8').replace('=', '')

        login_payload = {
            'username': self.username,
            'password': self.password
        }
        headers = {'Content-Type': 'application/x-www-form-urlencoded'}

        resp = requests.post("https://sso.arubainstanton.com/aio/api/v1/mfa/validate/full", data=login_payload, headers=headers, timeout=20)
        resp.raise_for_status()
        session_data = resp.json()
        session_token = session_data.get('access_token')
        if not session_token:
            raise RuntimeError("Failed to obtain sessionToken from Aruba Instant On SSO.")

        settings_resp = requests.get("https://portal.arubainstanton.com/settings.json", timeout=15)
        settings_resp.raise_for_status()
        client_id = settings_resp.json().get('ssoClientIdAuthZ', 'instant-on')

        authz_url = (
            f"https://sso.arubainstanton.com/as/authorization.oauth2"
            f"?client_id={client_id}&redirect_uri=https://portal.arubainstanton.com"
            f"&response_type=code&scope=profile%20openid&state={state}"
            f"&code_challenge_method=S256&code_challenge={code_challenge}"
            f"&sessionToken={session_token}"
        )
        authz_resp = requests.get(authz_url, allow_redirects=True, timeout=20)
        redirect_url = authz_resp.url

        if '?' not in redirect_url:
            raise RuntimeError(f"Expected code in redirect URL, got: {redirect_url}")

        query_params = redirect_url.split('?')[1].split('&')
        login_code = None
        for param in query_params:
            if '=' in param:
                k, v = param.split('=', 1)
                if k == 'code':
                    login_code = v
                    break

        if not login_code:
            raise RuntimeError(f"Could not extract OAuth authorization code from redirect URL: {redirect_url}")

        token_payload = {
            'client_id': client_id,
            'redirect_uri': 'https://portal.arubainstanton.com',
            'code': login_code,
            'code_verifier': code_verifier,
            'grant_type': 'authorization_code'
        }
        token_resp = requests.post("https://sso.arubainstanton.com/as/token.oauth2", data=token_payload, headers=headers, timeout=20)
        token_resp.raise_for_status()
        token_data = token_resp.json()

        self.access_token = token_data['access_token']
        expires_in = int(token_data.get('expires_in', 3600))
        self.token_expiry = time.time() + expires_in - 60
        logger.info(f"Successfully authenticated against Aruba Instant On SSO. Token valid for {expires_in}s.")

    def get_token(self):
        if not self.access_token or time.time() >= self.token_expiry:
            self.authenticate()
        return self.access_token

    def request(self, path):
        import requests

        token = self.get_token()
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
        url = f"https://nb.portal.arubainstanton.com/api/{path.lstrip('/')}"
        resp = requests.get(url, headers=headers, timeout=20)
        if resp.status_code == 401:
            logger.info("Token expired or rejected (401), refreshing...")
            self.authenticate()
            headers['Authorization'] = f'Bearer {self.access_token}'
            resp = requests.get(url, headers=headers, timeout=20)
        resp.raise_for_status()
        return resp.json()

def scrape_cycle(client):
    try:
        sites_resp = client.request("sites/")
        sites = sites_resp if isinstance(sites_resp, list) else sites_resp.get('items', [])
        AIO_SITES_TOTAL.set(len(sites))

        # Clear previous gauges before populating fresh data
        AIO_DEVICE_STATUS.clear()
        AIO_DEVICE_CLIENTS.clear()
        AIO_CLIENT_CONNECTED.clear()
        AIO_CLIENT_RSSI.clear()
        AIO_CLIENT_TX_RATE.clear()
        AIO_CLIENT_RX_RATE.clear()
        AIO_CLIENTS_TOTAL.clear()
        AIO_NETWORK_CLIENTS.clear()
        AIO_ALERTS_OPEN.clear()

        for site in sites:
            site_id = site.get('id')
            site_name = site.get('name') or site_id or 'default'

            # 1. Device Inventory
            try:
                inventory_resp = client.request(f"sites/{site_id}/inventory")
                devices = inventory_resp if isinstance(inventory_resp, list) else inventory_resp.get('items', [])
                for dev in devices:
                    name = dev.get('name') or dev.get('deviceName') or 'Unknown'
                    model = dev.get('model') or dev.get('deviceType') or 'Unknown'
                    serial = dev.get('serialNumber') or dev.get('serial') or ''
                    mac = dev.get('macAddress') or dev.get('mac') or ''
                    ip = dev.get('ipAddress') or dev.get('ip') or ''
                    status_str = str(dev.get('status', '')).lower()
                    is_up = 1 if status_str in ('normal', 'online', 'connected', 'up') or dev.get('connected') is True else 0
                    clients = int(dev.get('clientCount') or dev.get('connectedClients') or 0)

                    AIO_DEVICE_STATUS.labels(site=site_name, name=name, model=model, serial=serial, mac=mac, ip=ip).set(is_up)
                    AIO_DEVICE_CLIENTS.labels(site=site_name, name=name, model=model, mac=mac).set(clients)
            except Exception as e:
                logger.warning(f"Error fetching inventory for site {site_name}: {e}")

            # 2. Client Summary
            try:
                client_resp = client.request(f"sites/{site_id}/clientSummary")
                clients = client_resp if isinstance(client_resp, list) else client_resp.get('items', [])
                AIO_CLIENTS_TOTAL.labels(site=site_name).set(len(clients))

                for c in clients:
                    c_name = c.get('name') or c.get('clientName') or c.get('hostname') or 'Unknown'
                    c_mac = c.get('macAddress') or c.get('mac') or ''
                    c_ip = c.get('ipAddress') or c.get('ip') or ''
                    ap_name = c.get('connectedDeviceName') or c.get('apName') or c.get('deviceName') or 'Unknown'
                    ssid = c.get('networkName') or c.get('ssid') or 'Unknown'
                    band = str(c.get('band') or c.get('frequency') or 'unknown')

                    AIO_CLIENT_CONNECTED.labels(
                        site=site_name, name=c_name, mac=c_mac, ip=c_ip,
                        ap=ap_name, ssid=ssid, band=band
                    ).set(1)

                    rssi = c.get('signalStrength') or c.get('rssi')
                    if rssi is not None:
                        try:
                            AIO_CLIENT_RSSI.labels(
                                site=site_name, name=c_name, mac=c_mac,
                                ap=ap_name, ssid=ssid
                            ).set(float(rssi))
                        except ValueError:
                            pass

                    tx_rate = c.get('txRate') or c.get('phyTxRate')
                    if tx_rate is not None:
                        try:
                            AIO_CLIENT_TX_RATE.labels(site=site_name, name=c_name, mac=c_mac, ap=ap_name).set(float(tx_rate))
                        except ValueError:
                            pass

                    rx_rate = c.get('rxRate') or c.get('phyRxRate')
                    if rx_rate is not None:
                        try:
                            AIO_CLIENT_RX_RATE.labels(site=site_name, name=c_name, mac=c_mac, ap=ap_name).set(float(rx_rate))
                        except ValueError:
                            pass
            except Exception as e:
                logger.warning(f"Error fetching clientSummary for site {site_name}: {e}")

            # 3. Networks Summary
            try:
                networks_resp = client.request(f"sites/{site_id}/networksSummary")
                networks = networks_resp if isinstance(networks_resp, list) else networks_resp.get('items', [])
                for net in networks:
                    ssid = net.get('name') or net.get('networkName') or 'Unknown'
                    clients_count = int(net.get('clientCount') or net.get('connectedClients') or 0)
                    AIO_NETWORK_CLIENTS.labels(site=site_name, ssid=ssid).set(clients_count)
            except Exception as e:
                logger.warning(f"Error fetching networksSummary for site {site_name}: {e}")

            # 4. Alerts Summary
            try:
                alerts_resp = client.request(f"sites/{site_id}/alertsSummary")
                open_alerts = int(alerts_resp.get('openAlerts') or alerts_resp.get('count') or 0)
                AIO_ALERTS_OPEN.labels(site=site_name).set(open_alerts)
            except Exception as e:
                logger.warning(f"Error fetching alertsSummary for site {site_name}: {e}")

        AIO_UP.set(1)
        logger.info("Scrape cycle completed successfully.")
    except Exception as e:
        AIO_UP.set(0)
        logger.error(f"Scrape cycle failed: {e}")

def main():
    port = int(os.environ.get('AIO_EXPORTER_PORT', 9590))
    interval = int(os.environ.get('AIO_SCRAPE_INTERVAL', 60))
    username = os.environ.get('AIO_USERNAME')
    password = os.environ.get('AIO_PASSWORD')

    start_http_server(port)
    logger.info(f"Aruba Instant On exporter listening on port {port}")

    if not username or not password:
        logger.warning("AIO_USERNAME or AIO_PASSWORD not set. Exporter running in stub mode (exposing aruba_instant_on_up=0).")
        AIO_UP.set(0)
        while True:
            time.sleep(interval)

    client = ArubaInstantOnClient(username, password)
    while True:
        scrape_cycle(client)
        time.sleep(interval)

if __name__ == '__main__':
    main()
