#!/bin/bash
# ⬡ POLYGONE VPS RUNNER — by Hope

# 1. Start pulse FIRST, wait until it binds before starting the node
echo "Launching Polygone Pulse (Health Check)..."
python3 pulse.py &

PORT="${PORT:-8080}"
for i in $(seq 1 30); do
    if curl -s -o /dev/null "http://127.0.0.1:${PORT}/"; then
        echo " [✓] Pulse ready on :${PORT}"
        break
    fi
    sleep 0.5
done

# 2. Start the P2P node
echo "Launching Polygone Node..."
exec polygone-server "$@"
