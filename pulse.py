import http.server
import socketserver
import os
import threading
import time
import urllib.request

PORT = int(os.environ.get("PORT", "8080"))
URL  = os.environ.get("RENDER_URL")

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"POLYGONE PULSE: OK\n")

    def log_message(self, format, *args):
        pass  # silence access logs

def pinger():
    if not URL:
        return
    print(f" [▸] Self-ping active: {URL}")
    while True:
        try:
            time.sleep(600)
            urllib.request.urlopen(URL, timeout=10).read()
            print(f" [·] Pulse OK")
        except Exception as e:
            print(f" [!] Pulse failed: {e}")

if __name__ == "__main__":
    threading.Thread(target=pinger, daemon=True).start()
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        httpd.allow_reuse_address = True
        print(f" [✓] Pulse server on :{PORT}")
        httpd.serve_forever()
