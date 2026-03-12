#!/usr/bin/env python3
"""Simple HTTP server for router dashboard with API endpoint"""

import http.server
import socketserver
import subprocess
import json
from pathlib import Path

class RouterAPIHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/api/status':
            # Execute the network status script and return JSON
            try:
                result = subprocess.run(
                    ['/etc/router-dashboard/network-status.sh'],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                
                if result.returncode == 0:
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.end_headers()
                    self.wfile.write(result.stdout.encode())
                else:
                    self.send_error(500, f"Script failed: {result.stderr}")
            except subprocess.TimeoutExpired:
                self.send_error(504, "Script timeout")
            except Exception as e:
                self.send_error(500, f"Error: {str(e)}")
        else:
            # Serve static files from /etc/router-dashboard
            super().do_GET()

def run_server(port=8888, bind='10.10.10.1'):
    handler = RouterAPIHandler
    
    with socketserver.TCPServer((bind, port), handler) as httpd:
        print(f"Router dashboard server listening on {bind}:{port}")
        httpd.serve_forever()

if __name__ == '__main__':
    # Change to the dashboard directory
    import os
    os.chdir('/etc/router-dashboard')
    run_server()
