#!/usr/bin/env python3
"""
Polygone Pulse — Health Check Server

This server provides:
- /health - Kubernetes-style health check
- /status - Node status (reads from /tmp/polygone_status.json)
- Self-ping to keep the container alive on platforms like Render
"""

import http.server
import socketserver
import os
import json
import threading
import time
import urllib.request
from datetime import datetime

PORT = int(os.environ.get("PORT", "8080"))
RENDER_URL = os.environ.get("RENDER_URL")

STATUS_FILE = "/tmp/polygone_status.json"

class PolygoneHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"OK\n")
            
        elif self.path == "/status":
            status = {"status": "unknown", "updated": datetime.now().isoformat()}
            try:
                with open(STATUS_FILE) as f:
                    status = json.load(f)
                    status["pulse_check"] = datetime.now().isoformat()
            except FileNotFoundError:
                pass
            except json.JSONDecodeError:
                pass
                
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(status, indent=2).encode())
            
        else:
            self.send_response(404)
            self.end_headers()
            
    def log_message(self, format, *args):
        print(f"  [PULSE] {format % args}")

def self_ping():
    """Keep the service alive by pinging itself periodically."""
    if not RENDER_URL:
        print("  [PULSE] Self-ping disabled (no RENDER_URL)")
        return
        
    print(f"  [PULSE] Self-ping enabled: {RENDER_URL}")
    while True:
        time.sleep(300)  # Every 5 minutes
        try:
            urllib.request.urlopen(RENDER_URL, timeout=10)
            print(f"  [PULSE] ✓ Self-ping OK")
        except Exception as e:
            print(f"  [PULSE] ✗ Self-ping failed: {e}")

if __name__ == "__main__":
    # Start self-ping in background
    ping_thread = threading.Thread(target=self_ping, daemon=True)
    ping_thread.start()
    
    # Start HTTP server
    with socketserver.TCPServer(("", PORT), PolygoneHandler) as httpd:
        httpd.allow_reuse_address = True
        print(f"  ⬡ PULSE listening on :{PORT}")
        print(f"  → GET /health - Health check")
        print(f"  → GET /status - Node status")
        httpd.serve_forever()
